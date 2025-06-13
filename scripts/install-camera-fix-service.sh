#!/usr/bin/env bash
set -euo pipefail

SERVICE_FILE="camera-fix.service"
SERVICE_SRC="$(dirname "$0")/$SERVICE_FILE"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
WANTS_DIR="$SYSTEMD_USER_DIR/graphical.target.wants"

# Ensure the systemd user directory exists
mkdir -p "$SYSTEMD_USER_DIR"

# Copy the service file
cp "$SERVICE_SRC" "$SYSTEMD_USER_DIR/$SERVICE_FILE"

# Ensure the wants directory exists
mkdir -p "$WANTS_DIR"

# Create the symlink (force overwrite if exists)
ln -sf "../$SERVICE_FILE" "$WANTS_DIR/$SERVICE_FILE"

# Reload systemd user units
systemctl --user daemon-reload

# Enable and start the service
systemctl --user enable --now "$SERVICE_FILE"

echo "✅ camera-fix.service installed, enabled, and started."
