#!/usr/bin/bash

time_str=$(date +%H:%M)
dayofweek=$(date +%A)
date_str=$(date +%Y年%-m月%-d日)

cat <<EOF
{
  "time": "$time_str",
  "dayofweek": "$dayofweek",
  "date": "$date_str"
}
EOF
