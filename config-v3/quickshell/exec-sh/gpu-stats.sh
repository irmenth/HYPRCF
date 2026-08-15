#!/usr/bin/bash

gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)

if [[ "$gpu_temp" =~ ^[0-9]+$ ]]; then
	gpu_temp_json="$gpu_temp"
else
	gpu_temp_json="null"
fi

cat <<EOF
{
  "temp_c": $gpu_temp_json
}
EOF
