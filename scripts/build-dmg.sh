#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Tuck"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/build/$APP_NAME.dmg"
STAGING_DIR="$ROOT_DIR/build/dmg-staging"

"$ROOT_DIR/scripts/build-app.sh"

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"
printf 'Built %s\n' "$DMG_PATH"
