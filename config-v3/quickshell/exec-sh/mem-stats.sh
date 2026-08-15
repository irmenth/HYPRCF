#!/usr/bin/bash

# 初始化变量
total=0
available=0

# 读取 /proc/meminfo
while read -r key value _; do
	case "$key" in
	MemTotal:)
		total=$value
		;;
	MemAvailable:)
		available=$value
		;;
	esac
done </proc/meminfo

# 计算已用内存
used=$((total - available))

# 计算已用百分比
if [ "$total" -gt 0 ]; then
	used_percent=$(awk "BEGIN {printf \"%.1f\", $used * 100 / $total}")
else
	used_percent="0.0"
fi

if ! [[ "$used_percent" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	used_percent="0.0"
fi

cat <<EOF
{
  "total_kb": $total,
  "used_kb": $used,
  "used_percent": $used_percent
}
EOF
