#!/usr/bin/env bash
set -euo pipefail

# Configuration
CURSOR_SETTINGS_DIR="$HOME/.config/Cursor/User"
CURSOR_SETTINGS_FILE="$CURSOR_SETTINGS_DIR/settings.json"
CURSOR_SETTINGS_BACKUP="$CURSOR_SETTINGS_FILE.backup"
REPO_SETTINGS_FILE="$(dirname "$(dirname "$(realpath "$0")")")/.config/Cursor/User/settings.json"

# Ensure Cursor settings directory exists
mkdir -p "$CURSOR_SETTINGS_DIR"

# Function to check if Cursor is running
is_cursor_running() {
    pgrep -f "cursor.AppImage" > /dev/null
}

# Function to backup current settings
backup_settings() {
    if [ -f "$CURSOR_SETTINGS_FILE" ]; then
        echo "Backing up current settings to $CURSOR_SETTINGS_BACKUP"
        cp "$CURSOR_SETTINGS_FILE" "$CURSOR_SETTINGS_BACKUP"
    fi
}

# Function to restore settings from backup
restore_settings() {
    if [ -f "$CURSOR_SETTINGS_BACKUP" ]; then
        echo "Restoring settings from backup"
        cp "$CURSOR_SETTINGS_BACKUP" "$CURSOR_SETTINGS_FILE"
    fi
}

# Main sync logic
echo "Starting Cursor settings sync..."

# Check if Cursor is running
if is_cursor_running; then
    echo "Warning: Cursor is currently running. Please close Cursor before syncing settings."
    exit 1
fi

# Backup current settings
backup_settings

# Check if repo settings file exists
if [ ! -f "$REPO_SETTINGS_FILE" ]; then
    echo "Error: Repository settings file not found at $REPO_SETTINGS_FILE"
    restore_settings
    exit 1
fi

# Sync settings
echo "Syncing settings from repository..."
if cp "$REPO_SETTINGS_FILE" "$CURSOR_SETTINGS_FILE"; then
    echo "Settings synced successfully!"
else
    echo "Error: Failed to sync settings"
    restore_settings
    exit 1
fi

echo "Done!"
