#!/bin/bash

CURRENT_LAYOUT=$(hyprctl activeworkspace -j | jq -r '.layout')

if [ "$CURRENT_LAYOUT" = "dwindle" ]; then
    hyprctl dispatch layoutmsg layoutmaster
    notify-send -t 400 "Switched to Master layout"
else
    hyprctl dispatch layoutmsg layoutdwindle
    notify-send -t 400 "Switched to Dwindle layout"
fi
