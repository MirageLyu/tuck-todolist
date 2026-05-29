#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Tuck"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/build/$APP_NAME.dmg"
RW_DMG_PATH="$ROOT_DIR/build/$APP_NAME-rw.dmg"
STAGING_DIR="$ROOT_DIR/build/dmg-staging"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PATH="$ROOT_DIR/assets/dmg-background.png"
VOLUME_NAME="$APP_NAME"
MOUNT_DIR=""

cleanup() {
  if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  rm -rf "$STAGING_DIR" "$RW_DMG_PATH"
}
trap cleanup EXIT

if [[ ! -f "$BACKGROUND_PATH" ]]; then
  "$ROOT_DIR/scripts/generate-assets.sh"
fi

"$ROOT_DIR/scripts/build-app.sh"

rm -rf "$STAGING_DIR" "$DMG_PATH" "$RW_DMG_PATH"
mkdir -p "$BACKGROUND_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/"
cp "$BACKGROUND_PATH" "$BACKGROUND_DIR/dmg-background.png"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$RW_DMG_PATH" >/dev/null

MOUNT_DIR="$(hdiutil attach "$RW_DMG_PATH" -nobrowse -readwrite | awk '/\/Volumes\// {for (i = 3; i <= NF; i++) {printf "%s%s", (i == 3 ? "" : " "), $i}; print ""}' | tail -n 1)"

osascript <<OSA
set mountAlias to POSIX file "$MOUNT_DIR" as alias
set backgroundFile to POSIX file "$MOUNT_DIR/.background/dmg-background.png" as alias

tell application "Finder"
  open mountAlias
  set dmgWindow to container window of mountAlias
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set the bounds of dmgWindow to {160, 120, 800, 500}
  set viewOptions to icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 96
  set background picture of viewOptions to backgroundFile
  set position of item "$APP_NAME.app" of dmgWindow to {190, 205}
  set position of item "Applications" of dmgWindow to {450, 205}
  update mountAlias without registering applications
  delay 2
  close dmgWindow
end tell
OSA

sync
hdiutil detach "$MOUNT_DIR" -quiet
MOUNT_DIR=""

hdiutil convert "$RW_DMG_PATH" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH" >/dev/null

rm -rf "$STAGING_DIR" "$RW_DMG_PATH"
printf 'Built %s\n' "$DMG_PATH"
