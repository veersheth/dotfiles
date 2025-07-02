#!/bin/bash

#!/bin/bash

STATE_FILE="$HOME/.cache/hypr_caffeine"
PID_FILE="$HOME/.cache/hypr_caffeine_pid"

# Start caffeine mode
start_caffeine() {
    systemd-inhibit --what=idle:sleep --why="Caffeine mode" --mode=block sleep infinity &
    echo $! > "$PID_FILE"
    echo "on" > "$STATE_FILE"
    notify-send -t 1000 "☕ Caffeinated" "System will not automatically lock"
}

# Stop caffeine mode
stop_caffeine() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi
    echo "off" > "$STATE_FILE"
    notify-send -t 1000 "💤 De-Caffeinated" "Auto sleep when system not in use"
}

# Toggle
if [ -f "$STATE_FILE" ] && grep -q "on" "$STATE_FILE"; then
    stop_caffeine
else
    start_caffeine
fi

