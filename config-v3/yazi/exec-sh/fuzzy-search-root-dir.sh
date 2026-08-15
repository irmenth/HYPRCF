#!/usr/bin/bash

selected=$(fd -t d . / --hidden | fzf)

[ -z "$selected" ] && exit 0

ya emit reveal "$selected"
