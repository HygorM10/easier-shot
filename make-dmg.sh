#!/bin/bash
# Builds EasierShot.app and packages it as a drag-to-Applications disk image:
# build/EasierShot.dmg
set -euo pipefail
cd "$(dirname "$0")"

VOLUME="EasierShot"
APP="build/EasierShot.app"
STAGING="build/dmg-staging"
TEMP_DMG="build/EasierShot-rw.dmg"
FINAL_DMG="build/EasierShot.dmg"

./build-app.sh

# Make sure no older installer volume is mounted.
if [ -d "/Volumes/$VOLUME" ]; then
    diskutil eject "/Volumes/$VOLUME" >/dev/null || true
fi

rm -rf "$STAGING" "$TEMP_DMG" "$FINAL_DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Read-write image first, so the Finder window layout can be set.
diskutil image create from "$STAGING" --volumeName "$VOLUME" --format UDSB "$TEMP_DMG" >/dev/null
diskutil image attach "$TEMP_DMG" >/dev/null

# Window layout: app on the left, Applications on the right. Cosmetic only, so a
# failure here (e.g. Finder automation not allowed) does not stop the build.
osascript <<APPLESCRIPT || echo "Aviso: não foi possível ajustar o layout da janela do instalador."
tell application "Finder"
    tell disk "$VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 140, 760, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 13
        set position of item "EasierShot.app" of container window to {150, 170}
        set position of item "Applications" of container window to {410, 170}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

sync
diskutil eject "/Volumes/$VOLUME" >/dev/null

# Compressed, read-only image for distribution.
diskutil image create from "$TEMP_DMG" --format UDZO "$FINAL_DMG" >/dev/null
rm -rf "$TEMP_DMG" "$STAGING"

echo "OK: $FINAL_DMG"
