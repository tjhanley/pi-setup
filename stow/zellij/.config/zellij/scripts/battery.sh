#!/bin/sh
# Pi has no battery — show CPU temperature instead
temp=$(awk '{printf "%.0f", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
case "${1:-pct}" in
    icon) printf "" ;;
    *)    printf "%s°C" "${temp:-?}" ;;
esac
