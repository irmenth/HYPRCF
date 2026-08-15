#!/usr/bin/bash

get_active_interface() {
	local iface

	# 优先选择默认路由的接口
	iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')

	# 备选：有 IPv4 地址且非 lo 的接口
	if [ -z "$iface" ]; then
		iface=$(ip -o addr show 2>/dev/null | awk '$3 == "inet" {print $2}' | cut -d'@' -f1 | grep -v lo | head -n1)
	fi

	# 最后备选：状态为 UP 的接口
	if [ -z "$iface" ]; then
		iface=$(ip -o link show 2>/dev/null | awk -F': ' '$3 ~ /UP/ && $2 !~ /lo/ {print $2}' | head -n1)
	fi

	printf "%s" "$iface"
}

read_stats() {
	local iface="$1"
	awk -v iface="${iface}:" '$1 == iface {print $2, $10}' /proc/net/dev
}

interface=$(get_active_interface)

if [ -z "$interface" ]; then
	cat <<EOF
{
  "download_bps": 0,
  "upload_bps": 0,
  "interface": null
}
EOF
	exit 0
fi

read -r rx_bytes1 tx_bytes1 <<<"$(read_stats "$interface")"

if [ -z "$rx_bytes1" ] || [ -z "$tx_bytes1" ]; then
	cat <<EOF
{
  "download_bps": 0,
  "upload_bps": 0,
  "interface": "$interface"
}
EOF
	exit 0
fi

sleep 1

read -r rx_bytes2 tx_bytes2 <<<"$(read_stats "$interface")"

if [ -z "$rx_bytes2" ] || [ -z "$tx_bytes2" ]; then
	cat <<EOF
{
  "download_bps": 0,
  "upload_bps": 0,
  "interface": "$interface"
}
EOF
	exit 0
fi

rx_diff=$((rx_bytes2 - rx_bytes1))
tx_diff=$((tx_bytes2 - tx_bytes1))

# 防止极端情况下的负数
if [ "$rx_diff" -lt 0 ]; then
	rx_diff=0
fi

if [ "$tx_diff" -lt 0 ]; then
	tx_diff=0
fi

download_speed=$(awk "BEGIN {printf \"%.0f\", $rx_diff}")
upload_speed=$(awk "BEGIN {printf \"%.0f\", $tx_diff}")

cat <<EOF
{
  "download_bps": $download_speed,
  "upload_bps": $upload_speed,
  "interface": "$interface"
}
EOF
