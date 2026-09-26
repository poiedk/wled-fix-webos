#!/bin/sh

DB="/home/root/.hyperion/db/hyperion.db"
SERVICE="org.webosbrew.hyperion.ng.loader.service"

fail() {
  echo "ERROR: $1"
  exit 1
}

[ -r "$DB" ] || fail "Hyperion database not found: $DB"
command -v ifconfig >/dev/null 2>&1 || fail "ifconfig not found"
command -v wget >/dev/null 2>&1 || fail "wget not found"
command -v sqlite3 >/dev/null 2>&1 || fail "sqlite3 not found"

MYIP=$(ifconfig wlan0 2>/dev/null | sed -n 's/.*inet addr:\([0-9.]*\).*/\1/p')
[ -n "$MYIP" ] || fail "No IPv4 address found on wlan0"

NET=$(echo "$MYIP" | cut -d. -f1-3)
[ -n "$NET" ] || fail "Could not determine current subnet"

echo "TV IP: $MYIP"
echo "Searching WLED on $NET.0/24 ..."

WLED_IP=""
i=1

while [ "$i" -le 254 ]; do
  IP="$NET.$i"

  if [ "$IP" != "$MYIP" ]; then
    INFO=$(wget -T 1 -qO- "http://$IP/json/info" 2>/dev/null)

    echo "$INFO" | grep -q '"brand":"WLED"' && {
      WLED_IP="$IP"
      break
    }
  fi

  i=$((i + 1))
done

[ -n "$WLED_IP" ] || fail "WLED not found"

echo "WLED found: $WLED_IP"

OLD=$(sqlite3 "$DB"   "SELECT config FROM settings WHERE type='device' AND hyperion_inst=0;" 2>/dev/null |
  sed -n 's/.*"host":"\([^"]*\)".*/\1/p')

[ -n "$OLD" ] || fail "Could not read current Hyperion WLED host"

echo "Current Hyperion target: $OLD"

if [ "$OLD" = "$WLED_IP" ]; then
  echo "Already correct. Nothing to do."
  exit 0
fi

cp "$DB" "$DB.wled-auto-backup" || fail "Could not create Hyperion DB backup"

sqlite3 "$DB" "
UPDATE settings
SET config = replace(
               replace(
                 config,
                 '"host":"$OLD"',
                 '"host":"$WLED_IP"'
               ),
               '"hostList":"$OLD"',
               '"hostList":"$WLED_IP"'
             ),
    updated_at = datetime('now')
WHERE type='device'
  AND hyperion_inst=0;
" || fail "Could not update Hyperion database"

NEW=$(sqlite3 "$DB"   "SELECT config FROM settings WHERE type='device' AND hyperion_inst=0;" 2>/dev/null |
  sed -n 's/.*"host":"\([^"]*\)".*/\1/p')

[ "$NEW" = "$WLED_IP" ] || fail "Hyperion target verification failed"

echo "Hyperion target changed: $OLD -> $WLED_IP"

luna-send -n 1 "luna://$SERVICE/stop" '{}' >/dev/null 2>&1
sleep 2
luna-send -n 1 "luna://$SERVICE/start" '{}' >/dev/null 2>&1

echo "Hyperion restarted."
exit 0
