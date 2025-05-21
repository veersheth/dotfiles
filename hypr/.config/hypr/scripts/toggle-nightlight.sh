#!/bin/bash

NIGHT_TEMP=4500

if pgrep -x "hyprsunset" > /dev/null; then
    killall hyprsunset
    notify-send "Nightlight off"
else
    hyprsunset &
    sleep 0.2
    hyprctl hyprsunset temperature 4000
    notify-send "Nightlight on"
fi



