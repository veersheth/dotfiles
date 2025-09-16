#!/usr/bin/env bash

hyprlock &
sleep 0.5

if read -t 5 -n 1; then
    notify-send -u critical -t 0 "hello"
else
    systemctl suspend
fi

