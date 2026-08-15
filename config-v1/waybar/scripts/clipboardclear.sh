#!/bin/bash

# file path
target_directory=$HOME/.cache/cliphist/db

# make sure it exist
if [ -e "$target_directory" ]; then
    # remove it
    rm -f "$target_directory"
    notify-send "cliphist history has been removed"
else
    notify-send -u critical "$target_directory do not exist"
fi
