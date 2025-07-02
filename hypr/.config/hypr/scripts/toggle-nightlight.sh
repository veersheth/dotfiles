#!/bin/bash

# Temp file to store the current nightlight index
STATE_FILE="/tmp/hyprsunset_state"
TEMPS=(4500 3000 1500 OFF)

# Get the next index
if [[ -f "$STATE_FILE" ]]; then
    index=$(<"$STATE_FILE")
    index=$(( (index + 1) % ${#TEMPS[@]} ))
else
    index=0
fi

# Save new index
echo "$index" > "$STATE_FILE"

# Act based on the selected state
temp="${TEMPS[$index]}"

if [[ "$temp" == "OFF" ]]; then
    killall hyprsunset 2>/dev/null
    notify-send -t 500 "Nightlight off"
else
    # Start hyprsunset if not running
    if ! pgrep -x "hyprsunset" > /dev/null; then
        hyprsunset &
        sleep 0.2
    fi

    hyprctl hyprsunset temperature "$temp"
    notify-send -t 500 "Nightlight: $temp K"
fi

