#!/bin/bash
set -euo pipefail

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if v4l2-ctl is available
if ! command -v v4l2-ctl &> /dev/null; then
    log "ERROR: v4l2-ctl not found. Please install v4l-utils."
    exit 1
fi

# Check if camera device exists
if [ ! -e "/dev/video2" ]; then
    log "ERROR: Camera device /dev/video2 not found."
    exit 1
fi

# Function to set camera control with error handling
set_camera_control() {
    local control="$1"
    local value="$2"
    if ! v4l2-ctl -d /dev/video2 --set-ctrl="$control=$value" 2>/dev/null; then
        log "WARNING: Failed to set $control to $value"
    else
        log "Set $control to $value"
    fi
}

# Apply camera settings
log "Applying camera settings..."

set_camera_control brightness 128
set_camera_control contrast 128
set_camera_control saturation 128
set_camera_control white_balance_temperature_auto 0
set_camera_control gain 142
set_camera_control power_line_frequency 2
set_camera_control sharpness 128
set_camera_control backlight_compensation 1
set_camera_control exposure_auto_priority 0
set_camera_control focus_auto 0
set_camera_control focus_absolute 0
set_camera_control zoom_absolute 0
set_camera_control exposure_absolute 77
set_camera_control white_balance_temperature 5715
set_camera_control exposure_auto 3

log "Camera settings applied successfully"
