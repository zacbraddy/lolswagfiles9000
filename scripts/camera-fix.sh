#!/bin/bash
set -euo pipefail

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Debug function
debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        log "DEBUG: $1"
    fi
}

# Check if v4l2-ctl is available
if ! command -v v4l2-ctl &> /dev/null; then
    log "ERROR: v4l2-ctl not found. Please install v4l-utils."
    exit 1
fi

# List available video devices
debug "Available video devices:"
v4l2-ctl --list-devices

# Try to find the Logitech camera device
CAMERA_DEVICE="${V4L2_DEVICE:-}"
if [ -z "$CAMERA_DEVICE" ]; then
    for dev in /dev/video*; do
        if v4l2-ctl -d "$dev" --all 2>/dev/null | grep -q "Logitech"; then
            CAMERA_DEVICE="$dev"
            debug "Found Logitech camera at $CAMERA_DEVICE"
            break
        fi
    done
fi

# If no device found, try /dev/video2 as fallback
if [ -z "$CAMERA_DEVICE" ]; then
    CAMERA_DEVICE="/dev/video2"
    debug "Using fallback device $CAMERA_DEVICE"
fi

# Check if camera device exists
if [ ! -e "$CAMERA_DEVICE" ]; then
    log "ERROR: Camera device $CAMERA_DEVICE not found."
    exit 1
fi

# Function to set camera control with error handling
set_camera_control() {
    local control="$1"
    local value="$2"
    if ! v4l2-ctl -d "$CAMERA_DEVICE" --set-ctrl="$control=$value" 2>/dev/null; then
        log "WARNING: Failed to set $control to $value"
    else
        log "Set $control to $value"
    fi
}

# Apply camera settings
log "Applying camera settings to $CAMERA_DEVICE..."

# List available controls
debug "Available controls:"
v4l2-ctl -d "$CAMERA_DEVICE" --list-ctrls

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
