#!/usr/bin/env bash

set -u

tmp="$(mktemp --suffix=.png)"
picker_pid=""

cleanup() {
	if [[ -n "${picker_pid:-}" ]]; then
		kill "$picker_pid" 2>/dev/null || true
		wait "$picker_pid" 2>/dev/null || true
	fi

	rm -f "$tmp"
}

trap cleanup EXIT INT TERM

# 冻结当前屏幕画面
hyprpicker -r -z >/dev/null 2>&1 &
picker_pid=$!

# 给 hyprpicker 一点时间完成冻结
sleep 0.2

# 在冻结画面上选择区域
region="$(slurp)" || exit 0

[[ -n "$region" ]] || exit 0

# 趁屏幕仍被冻结时截图
grim -g "$region" "$tmp" || exit 1

# 截图完成，解除冻结
kill "$picker_pid" 2>/dev/null || true
wait "$picker_pid" 2>/dev/null || true
picker_pid=""

# 复制到剪贴板
wl-copy <"$tmp"

# 打开 satty 标注
satty --filename "$tmp"
