#!/bin/sh

DB="/home/root/.hyperion/db/hyperion.db"
SERVICE="org.webosbrew.hyperion.ng.loader.service"

IFACE="wlan0"
TIMEOUT="1"
INSTANCE="0"
FAST="1"
FULL="1"
VERIFY="1"
RESTART="1"
BACKUP="1"
KEEP_BACKUPS="3"
TEST_LEDS="0"
VERBOSE="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --iface) IFACE="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --instance) INSTANCE="$2"; shift 2 ;;
    --fast) FAST="$2"; shift 2 ;;
    --full) FULL="$2"; shift 2 ;;
    --verify) VERIFY="$2"; shift 2 ;;
    --restart) RESTART="$2"; shift 2 ;;
    --backup) BACKUP="$2"; shift 2 ;;
    --keep-backups) KEEP_BACKUPS="$2"; shift 2 ;;
    --test-leds) TEST_LEDS="$2"; shift 2 ;;
    --verbose) VERBOSE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

emit() {
  echo "$1=$2"
}

log() {
  [ "$VERBOSE" = "1" ] && emit "LOG" "$1"
}

fail() {
  emit "RESULT" "ERROR"
  emit "ERROR" "$1"
  exit 1
}

case "$TIMEOUT" in 1|2) ;; *) TIMEOUT="1" ;; esac
case "$INSTANCE" in ''|*[!0-9]*) INSTANCE="0" ;; esac
case "$KEEP_BACKUPS" in 1|3|5) ;; *) KEEP_BACKUPS="3" ;; esac
case "$IFACE" in *[!A-Za-z0-9_.:-]*|'') IFACE="wlan0" ;; esac

[ -r "$DB" ] || fail "Hyperion database not found"
command -v ifconfig >/dev/null 2>&1 || fail "ifconfig not found"
command -v wget >/dev/null 2>&1 || fail "wget not found"
command -v sqlite3 >/dev/null 2>&1 || fail "sqlite3 not found"

MYIP=$(ifconfig "$IFACE" 2>/dev/null | sed -n 's/.*inet addr:\([0-9.]*\).*/\1/p')
[ -n "$MYIP" ] || fail "No IPv4 address found on $IFACE"
NET=$(echo "$MYIP" | cut -d. -f1-3)
[ -n "$NET" ] || fail "Could not determine current subnet"

emit "TV_IP" "$MYIP"
emit "SUBNET" "$NET.0/24"

CONFIG=$(sqlite3 "$DB" "SELECT config FROM settings WHERE type='device' AND hyperion_inst=$INSTANCE;" 2>/dev/null)
[ -n "$CONFIG" ] || fail "Hyperion device config not found for instance $INSTANCE"

OLD=$(echo "$CONFIG" | sed -n 's/.*"host":"\([^"]*\)".*/\1/p')
[ -n "$OLD" ] || fail "Could not read current Hyperion WLED host"
emit "HYPERION_TARGET" "$OLD"

is_wled() {
  CANDIDATE="$1"
  [ -n "$CANDIDATE" ] || return 1
  INFO=$(wget -T "$TIMEOUT" -qO- "http://$CANDIDATE/json/info" 2>/dev/null)
  echo "$INFO" | grep -q '"brand":"WLED"'
}

WLED_IP=""

if [ "$FAST" = "1" ]; then
  log "Testing current Hyperion target"
  case "$OLD" in
    "$NET".*)
      if is_wled "$OLD"; then
        WLED_IP="$OLD"
        emit "DISCOVERY" "CURRENT_TARGET"
      fi
      ;;
  esac

  if [ -z "$WLED_IP" ] && [ -r /proc/net/arp ]; then
    log "Checking ARP candidates"
    for IP in $(awk 'NR>1 {print $1}' /proc/net/arp 2>/dev/null); do
      case "$IP" in
        "$NET".*)
          [ "$IP" = "$MYIP" ] && continue
          if is_wled "$IP"; then
            WLED_IP="$IP"
            emit "DISCOVERY" "ARP"
            break
          fi
          ;;
      esac
    done
  fi
fi

if [ -z "$WLED_IP" ] && [ "$FULL" = "1" ]; then
  emit "DISCOVERY" "FULL_SCAN"
  i=1
  while [ "$i" -le 254 ]; do
    IP="$NET.$i"
    if [ "$IP" != "$MYIP" ] && is_wled "$IP"; then
      WLED_IP="$IP"
      break
    fi
    i=$((i + 1))
  done
fi

[ -n "$WLED_IP" ] || fail "WLED not found on $NET.0/24"
emit "WLED_IP" "$WLED_IP"

UPDATED="0"

if [ "$OLD" != "$WLED_IP" ]; then
  if [ "$BACKUP" = "1" ]; then
    TS=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo now)
    BACKUP_FILE="$DB.wledfix-$TS.bak"
    cp "$DB" "$BACKUP_FILE" || fail "Could not create Hyperion DB backup"
    emit "BACKUP" "$BACKUP_FILE"

    if [ "$KEEP_BACKUPS" -gt 0 ] 2>/dev/null; then
      N=0
      for F in $(ls -1t "$DB".wledfix-*.bak 2>/dev/null); do
        N=$((N + 1))
        [ "$N" -le "$KEEP_BACKUPS" ] || rm -f "$F"
      done
    fi
  fi

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
  AND hyperion_inst=$INSTANCE;
" || fail "Could not update Hyperion database"

  NEW=$(sqlite3 "$DB" "SELECT config FROM settings WHERE type='device' AND hyperion_inst=$INSTANCE;" 2>/dev/null |
    sed -n 's/.*"host":"\([^"]*\)".*/\1/p')

  [ "$NEW" = "$WLED_IP" ] || fail "Hyperion target verification failed"

  UPDATED="1"
  emit "OLD_TARGET" "$OLD"
  emit "NEW_TARGET" "$NEW"

  if [ "$RESTART" = "1" ]; then
    luna-send -n 1 "luna://$SERVICE/stop" '{}' >/dev/null 2>&1
    sleep 2
    luna-send -n 1 "luna://$SERVICE/start" '{}' >/dev/null 2>&1
    emit "RESTARTED" "1"
    sleep 3
  else
    emit "RESTARTED" "0"
  fi
fi

if [ "$VERIFY" = "1" ]; then
  SERVER=$(wget -T 2 -qO- http://127.0.0.1:8090/json-rpc     --post-data='{"command":"serverinfo","tan":91}'     --header='Content-Type: application/json' 2>/dev/null | tr -d '\r\n ')
  echo "$SERVER" | grep -q '"enabled":true,"name":"LEDDEVICE"' && emit "VERIFY" "OK" || emit "VERIFY" "FAILED"
else
  emit "VERIFY" "SKIPPED"
fi

if [ "$TEST_LEDS" = "1" ]; then
  wget -T 2 -qO- http://127.0.0.1:8090/json-rpc     --post-data='{"command":"color","color":[0,80,255],"priority":50,"duration":700,"tan":92}'     --header='Content-Type: application/json' >/dev/null 2>&1
  emit "LED_TEST" "SENT"
fi

if [ "$UPDATED" = "1" ]; then
  emit "RESULT" "UPDATED"
else
  emit "RESULT" "OK"
fi

exit 0
