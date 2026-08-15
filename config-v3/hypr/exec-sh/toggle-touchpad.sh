#!/usr/bin/bash

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/touchpad"
ENABLED_FILE="$STATE_DIR/enabled"

DEVICE=$(hyprctl devices -j | jq -r '.mice[] | select(.name | contains("touchpad")) | .name')

mkdir -p "$STATE_DIR"

if [ ! -f "$ENABLED_FILE" ]; then
	echo "false" >"$ENABLED_FILE"
fi

IS_ENABLED=$(cat "$ENABLED_FILE")

if [ "$IS_ENABLED" = "true" ]; then
	hyprctl eval 'hl.device({ name = "'$DEVICE'", enabled = false })'
	echo "false" >"$ENABLED_FILE"
	notify-send -u low -t 2000 "Touchpad" "已禁用"
else
	hyprctl eval 'hl.device({ name = "'$DEVICE'", enabled = true })'
	echo "true" >"$ENABLED_FILE"
	notify-send -u low -t 2000 "Touchpad" "已开启"
fi
