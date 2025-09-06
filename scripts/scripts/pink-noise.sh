#!/bin/bash

if pgrep -x play >/dev/null 2>&1; then
    pkill -x play
    notify-send -t 1000 "Pink noise" "Disabled"
else
    play -nq synth pinknoise vol 0.10 &
    notify-send -t 1000 "Pink noise" "Turned on"
fi

