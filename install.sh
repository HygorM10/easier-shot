#!/bin/bash
# Downloads the latest EasierShot release and installs it in /Applications.
set -euo pipefail

REPOSITORY="HygorM10/easier-shot"
DOWNLOAD_URL="https://github.com/$REPOSITORY/releases/latest/download/EasierShot.dmg"
WORK_DIR="$(mktemp -d)"
MOUNT_POINT="$WORK_DIR/mount"
DMG="$WORK_DIR/EasierShot.dmg"

cleanup() {
    if mount | grep -q "on $MOUNT_POINT "; then
        hdiutil detach "$MOUNT_POINT" -quiet || true
    fi
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if [ "$(uname -s)" != "Darwin" ]; then
    echo "EasierShot só pode ser instalado no macOS." >&2
    exit 1
fi

mkdir -p "$MOUNT_POINT"
echo "Baixando a versão mais recente..."
curl --fail --location --show-error --silent "$DOWNLOAD_URL" --output "$DMG"

osascript -e 'tell application "EasierShot" to quit' >/dev/null 2>&1 || true
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT_POINT" >/dev/null

if [ ! -d "$MOUNT_POINT/EasierShot.app" ]; then
    echo "O instalador não contém EasierShot.app." >&2
    exit 1
fi

echo "Instalando em /Applications..."
ditto "$MOUNT_POINT/EasierShot.app" "/Applications/EasierShot.app"
open "/Applications/EasierShot.app"
echo "EasierShot instalado com sucesso."
