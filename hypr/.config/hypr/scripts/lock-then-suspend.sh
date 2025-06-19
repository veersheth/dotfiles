#!/bin/bash

hyprlock &

activity_detected=false
monitor_input() {
    timeout 3 libinput debug-events --device /dev/input/event* 2>/dev/null | while read -r line; do
        if [[ "$line" =~ event[0-9]+ ]]; then
            activity_detected=true
            pkill -P $$ timeout
            break
        fi
    done
}

monitor_input &
monitor_pid=$!

wait $monitor_pid

if [ "$activity_detected" = false ]; then
    systemctl suspend
else
    notify-send "User activity detected, not sleeping"
fi

