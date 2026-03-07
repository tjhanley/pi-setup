#!/bin/sh
# Instant CPU usage from /proc/stat (averaged since boot; zjstatus polls every 5s)
awk 'NR==1{printf "%3.0f%%", ($2+$4)*100/($2+$4+$5)}' /proc/stat
