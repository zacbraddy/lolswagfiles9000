#!/bin/bash
v4l2-ctl -d /dev/video2
v4l2-ctl -d /dev/video2 --set-ctrl=brightness=128
v4l2-ctl -d /dev/video2 --set-ctrl=contrast=128
v4l2-ctl -d /dev/video2 --set-ctrl=saturation=128
v4l2-ctl -d /dev/video2 --set-ctrl=white_balance_temperature_auto=0
v4l2-ctl -d /dev/video2 --set-ctrl=gain=142
v4l2-ctl -d /dev/video2 --set-ctrl=power_line_frequency=2
v4l2-ctl -d /dev/video2 --set-ctrl=sharpness=128
v4l2-ctl -d /dev/video2 --set-ctrl=backlight_compensation=1
v4l2-ctl -d /dev/video2 --set-ctrl=exposure_auto=1
v4l2-ctl -d /dev/video2 --set-ctrl=exposure_auto_priority=0
v4l2-ctl -d /dev/video2 --set-ctrl=focus_auto=0
v4l2-ctl -d /dev/video2 --set-ctrl=focus_absolute=0
v4l2-ctl -d /dev/video2 --set-ctrl=zoom_absolute=0
v4l2-ctl -d /dev/video2 --set-ctrl=exposure_absolute=77
v4l2-ctl -d /dev/video2 --set-ctrl=white_balance_temperature=5715
