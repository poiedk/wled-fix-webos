#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_ID="org.webosbrew.wledfix"
VERSION="$(python3 - <<'PY'
import json
with open("app/appinfo.json","r",encoding="utf-8") as f:
    print(json.load(f)["version"])
PY
)"
OUT_DIR="$ROOT/dist"
WORK="$ROOT/.build"
PKG="$APP_ID"
APP_DEST="$WORK/data/media/developer/apps/usr/palm/applications/$APP_ID"

rm -rf "$WORK" "$OUT_DIR"
mkdir -p "$WORK/control" "$APP_DEST" "$OUT_DIR"

cp -a "$ROOT/app/." "$APP_DEST/"
chmod 755 "$APP_DEST/wled-auto.sh"

cat > "$WORK/control/control" <<EOF
Package: $PKG
Version: $VERSION
Architecture: all
Maintainer: poiedk
Description: One-click WLED rediscovery for Hyperion.NG on rooted LG webOS TVs.
Section: misc
Priority: optional
EOF

printf '2.0\n' > "$WORK/debian-binary"

tar -C "$WORK/control" -czf "$WORK/control.tar.gz" .
tar -C "$WORK/data" -czf "$WORK/data.tar.gz" .

(
  cd "$WORK"
  ar rcs "$OUT_DIR/${PKG}_${VERSION}_all.ipk" debian-binary control.tar.gz data.tar.gz
)

echo "Built: $OUT_DIR/${PKG}_${VERSION}_all.ipk"
