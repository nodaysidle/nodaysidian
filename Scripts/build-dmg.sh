#!/usr/bin/env bash
set -euo pipefail

CONF=${1:-release}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Nodaysidian"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR="${ROOT}/.build/dmg-staging"

cd "$ROOT"

SIGNING_MODE=${SIGNING_MODE:-adhoc} "${ROOT}/Scripts/package_app.sh" "$CONF"

rm -rf "$STAGING_DIR" "$ROOT/$DMG_NAME"
mkdir -p "$STAGING_DIR"
cp -R "$ROOT/${APP_NAME}.app" "$STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$ROOT/$DMG_NAME"

hdiutil verify "$ROOT/$DMG_NAME"
shasum -a 256 "$ROOT/$DMG_NAME"
