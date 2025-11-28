#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
    pkill hypridle
    notify-send "Caffeine enabled" "hypridle not running"
else
    nohup hypridle >/dev/null 2>&1 &
    notify-send "Caffeine disabled" "hypridle running"
fi

