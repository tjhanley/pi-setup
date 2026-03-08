#!/usr/bin/env bash
awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.1fG",(t-a)/1048576}' /proc/meminfo
