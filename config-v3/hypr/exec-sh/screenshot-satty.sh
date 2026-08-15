#!/bin/sh

tmp=$(mktemp --suffix=.png)

grim -g "$(slurp)" "$tmp" &&
	wl-copy <"$tmp" &&
	satty --filename "$tmp"

rm -f "$tmp"
