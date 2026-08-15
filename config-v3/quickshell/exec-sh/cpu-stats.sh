#!/usr/bin/bash

# --- CPU Usage ---
read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ </proc/stat
sleep 0.5
read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ </proc/stat

du=$((u2 - u1))
dn=$((n2 - n1))
ds=$((s2 - s1))
di=$((i2 - i1))
dw=$((w2 - w1))
dq=$((q2 - q1))
dsq=$((sq2 - sq1))
dst=$((st2 - st1))

total=$((du + dn + ds + di + dw + dq + dsq + dst))
idle=$((di + dw))

if [ "$total" -gt 0 ]; then
	cpu_usage=$(awk "BEGIN {printf \"%.1f\", ($total - $idle) * 100 / $total}")
else
	cpu_usage="0.0"
fi

if ! [[ "$cpu_usage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	cpu_usage="0.0"
fi

# --- CPU Frequency ---
sum=0
count=0

for freq_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
	if [ -f "$freq_file" ]; then
		freq=$(cat "$freq_file" 2>/dev/null)

		if [[ "$freq" =~ ^[0-9]+$ ]]; then
			sum=$((sum + freq))
			count=$((count + 1))
		fi
	fi
done

if [ "$count" -gt 0 ]; then
	cpu_freq=$(awk "BEGIN {printf \"%.2f\", $sum / $count / 1e6}")
else
	cpu_freq="0.00"
fi

if ! [[ "$cpu_freq" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	cpu_freq="0.00"
fi

# --- CPU Temperature ---
cpu_temp=$(sensors 2>/dev/null | awk '
    /^k10temp/ {
        found = 1
    }

    found && /Tctl/ {
        match($0, /\+([0-9.]+)/, a)
        if (a[1]) {
            printf "%.1f", a[1]
            exit
        }
    }
')

if [[ "$cpu_temp" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
	cpu_temp_json="$cpu_temp"
else
	cpu_temp_json="null"
fi

cat <<EOF
{
  "usage_percent": $cpu_usage,
  "freq_ghz": $cpu_freq,
  "temp_c": $cpu_temp_json
}
EOF
