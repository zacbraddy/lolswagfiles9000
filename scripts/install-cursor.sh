#!/usr/bin/env bash
set -euo pipefail

CURSOR_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
APPIMAGE_NAME="cursor.AppImage"
APPIMAGE_PATH="$CURSOR_DIR/$APPIMAGE_NAME"
MIMEAPPS="$HOME/.config/mimeapps.list"
CURSOR_DESKTOP="cursor.desktop"
CURSOR_DESKTOP_PATH="$DESKTOP_DIR/$CURSOR_DESKTOP"
CURSOR_SETTINGS_DIR="$HOME/.config/Cursor/User"
CURSOR_SETTINGS_FILE="$CURSOR_SETTINGS_DIR/settings.json"
GLOBAL_SETTINGS_FILE="$HOME/.config/Cursor/User/settings.json"

# Get latest release URL from Cursor's official API
LATEST_URL=$(curl -s 'https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable' | grep -oP '"downloadUrl":"\\K[^"]+')

if [ -z "$LATEST_URL" ]; then
  echo "Could not find a download URL for Cursor AppImage. Please check https://www.cursor.com/downloads"
  exit 1
fi

mkdir -p "$CURSOR_DIR" "$DESKTOP_DIR" "$(dirname $MIMEAPPS)"

# Download if not present or if newer
if [ ! -f "$APPIMAGE_PATH" ]; then
  echo "Downloading latest Cursor AppImage..."
  curl -L "$LATEST_URL" -o "$APPIMAGE_PATH"
  chmod +x "$APPIMAGE_PATH"
fi

# Create/update .desktop file
cat > "$CURSOR_DESKTOP_PATH" <<EOF
[Desktop Entry]
Name=Cursor
Exec=$APPIMAGE_PATH %U
Icon=cursor
Type=Application
Categories=Development;IDE;
Terminal=false
EOF

echo "Cursor AppImage installed to $APPIMAGE_PATH and .desktop file updated."

# Idempotent MIME association function
default_section='[Default Applications]'
add_mime_default() {
  local mime="$1"
  local desktop="$2"
  # Ensure section exists
  grep -qxF "$default_section" "$MIMEAPPS" || echo "$default_section" >> "$MIMEAPPS"
  # Remove any existing line for this mime type in Default Applications
  sed -i "/^$mime=/d" "$MIMEAPPS"
  # Add the correct line
  awk -v mime="$mime" -v desktop="$desktop" -v section="$default_section" '
    BEGIN {added=0}
    {print}
    $0==section && !added {print mime "=" desktop; added=1}
  ' "$MIMEAPPS" > "$MIMEAPPS.tmp" && mv "$MIMEAPPS.tmp" "$MIMEAPPS"
}

# List of MIME types to associate with Cursor
for mime in \
  application/json \
  application/javascript \
  text/x-python \
  text/x-shellscript
  do
    add_mime_default "$mime" "$CURSOR_DESKTOP"
done
