#!/usr/bin/bash

# --- 检查是否有电池 ---
battery_exists="false"

if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
	battery_exists="true"
fi

# --- 检查是否插电 ---
ac_online_json="null"

for ac_file in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
	if [ -f "$ac_file" ]; then
		ac_value=$(cat "$ac_file" 2>/dev/null)

		if [[ "$ac_value" =~ ^[0-9]+$ ]]; then
			ac_online_json="$ac_value"
		fi

		break
	fi
done

# --- 电池电量 ---
capacity_json="null"

if [ "$battery_exists" = "true" ]; then
	for bat_file in /sys/class/power_supply/BAT*/capacity; do
		if [ -f "$bat_file" ]; then
			capacity_value=$(cat "$bat_file" 2>/dev/null)

			if [[ "$capacity_value" =~ ^[0-9]+$ ]]; then
				capacity_json="$capacity_value"
			fi

			break
		fi
	done
fi

cat <<EOF
{
  "has_battery": $battery_exists,
  "ac_online": $ac_online_json,
  "capacity_percent": $capacity_json
}
EOF
