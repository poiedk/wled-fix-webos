#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/dist"

command -v ares-package >/dev/null 2>&1 || {
  echo "ERROR: ares-package is required."
  echo "Install the official webOS CLI: npm install -g @webos-tools/cli"
  exit 1
}

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cd "$ROOT"
ares-package --no-minify -o "$OUT_DIR" app

echo "Built package:"
ls -lh "$OUT_DIR"/*.ipk
