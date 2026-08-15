#!/usr/bin/bash

selected=$(fd -t f . ~/ --hidden | fzf)

[ -z "$selected" ] && exit 0

ya emit reveal "$selected"
