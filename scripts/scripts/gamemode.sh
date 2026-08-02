#!/usr/bin/env bash

STATE="/run/user/$(id -u)/gaming.state"


if [ -f "$STATE" ]; then
    qs ipc call ripple triggerColor "#ffffff"
    hyprctl reload
    powerprofilesctl set balanced 2>/dev/null || true
    rm "$STATE"
else
    hyprctl eval "animations:enabled = false"
    hyprctl eval "decoration:blur:enabled = false"
    hyprctl eval "decoration:drop_shadow = false"
    hyprctl eval "decoration:rounding = 0"
    powerprofilesctl set performance 2>/dev/null || true

    touch "$STATE"

    qs ipc call ripple triggerColor "#147db0"
    gamescope -f -w 1128 -h 752 -W 2256 -H 1504 -F fsr --expose-wayland -e -r 60 --borderless --force-grab-cursor -- steam

    GAMESCOPE_PID=$!

    until pgrep -x steam > /dev/null 2>&1; do sleep 0.3; done
    sleep 4

    wait $GAMESCOPE_PID

    hyprctl reload
    powerprofilesctl set balanced 2>/dev/null || true
    rm "$STATE"
fi
