#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="NodaysIdle"
APP_BUNDLE="${ROOT_DIR}/${APP_NAME}.app"
INSTALL_DIR="/Applications"

log() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

log "==> Building ${APP_NAME}..."
SIGNING_MODE=adhoc "${ROOT_DIR}/Scripts/package_app.sh" release

if [[ ! -d "$APP_BUNDLE" ]]; then
  fail "App bundle not found at $APP_BUNDLE"
fi

pkill -f "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 0.5

log "==> Installing to ${INSTALL_DIR}..."
rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
cp -R "$APP_BUNDLE" "${INSTALL_DIR}/${APP_NAME}.app"

log "==> Done! ${APP_NAME} installed to ${INSTALL_DIR}/${APP_NAME}.app"
log "==> Launching..."
open "${INSTALL_DIR}/${APP_NAME}.app"
