#!/bin/bash

STATE_FILE="/tmp/hyprsunset_state"

if [[ -f "$STATE_FILE" ]]; then
    STATE=$(cat "$STATE_FILE")
else
    STATE="OFF"
fi

turn_off() {
    pkill -9 hyprsunset 2>/dev/null
}

notify_short() {
    notify-send "Hyprsunset" "$1"
    sleep 0.5
    dunstctl close
}

case "$STATE" in
    "OFF")
        hyprsunset -t 6000 &
        echo "6000" > "$STATE_FILE"
        notify_short "Temperature: 6000K"
        ;;
    "6000")
        turn_off
        hyprsunset -t 4000 &
        echo "4000" > "$STATE_FILE"
        notify_short "Temperature: 4000K"
        ;;
    "4000")
        turn_off
        hyprsunset -t 2000 &
        echo "2000" > "$STATE_FILE"
        notify_short "Temperature: 2000K"
        ;;
    "2000")
        turn_off
        echo "OFF" > "$STATE_FILE"
        notify_short "Hyprsunset Off"
        ;;
    *)
        turn_off
        echo "OFF" > "$STATE_FILE"
        notify_short "Hyprsunset Off"
        ;;
esac

