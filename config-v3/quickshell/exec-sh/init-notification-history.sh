#!/usr/bin/env bash

set -e

DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell/notifications"
FILE="$DIR/notification-history.json"

mkdir -p "$DIR"

if [[ ! -f "$FILE" ]]; then
	printf '%s\n' '{"history":[]}' >"$FILE"
fi
