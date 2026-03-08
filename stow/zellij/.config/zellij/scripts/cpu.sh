#!/usr/bin/env bash
# CPU usage: two /proc/stat samples 200ms apart to get current utilization
awk 'NR==1{u1=$2+$4; t1=$2+$3+$4+$5+$6+$7+$8; next} NR==2{u2=$2+$4; t2=$2+$3+$4+$5+$6+$7+$8; printf "%3.0f%%\n", (u2-u1)*100/(t2-t1)}' \
    <(grep '^cpu ' /proc/stat) \
    <(sleep 0.2; grep '^cpu ' /proc/stat)
