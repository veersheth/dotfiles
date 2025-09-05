#!/usr/bin/env bash

THRESHOLDS=(10 15 20)  # warning thresholds
CRITICAL=5             # suspend threshold
INTERVAL=60            # seconds between checks
declare -A NOTIFIED     # associative array to track notifications for each threshold

while true; do
    PERCENT=$(cat /sys/class/power_supply/BAT*/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT*/status)  # "Charging", "Discharging", "Full"

    for THRESHOLD in "${THRESHOLDS[@]}"; do
        if [ "$PERCENT" -le "$THRESHOLD" ] && [ "$PERCENT" -gt "$CRITICAL" ]; then
            if [ "${NOTIFIED[$THRESHOLD]}" != "1" ]; then
                notify-send -u critical -t 0 "⚠ Low Battery" "Battery is at ${PERCENT}% (threshold ${THRESHOLD}%)"
                NOTIFIED[$THRESHOLD]=1
            fi
        else
            NOTIFIED[$THRESHOLD]=0
        fi
    done

    # suspend on critical battery
    if [ "$PERCENT" -le "$CRITICAL" ] && [ "$STATUS" != "Charging" ]; then
        notify-send -u critical -t 0 "Critical Battery" "Battery at ${PERCENT}%, suspending..."
        sleep 20
        # check again just in case the cable is plugged in
        if [ "$(cat /sys/class/power_supply/BAT*/status)" != "Charging" ]; then
            systemctl suspend
        fi
    fi

    sleep "$INTERVAL"
done

