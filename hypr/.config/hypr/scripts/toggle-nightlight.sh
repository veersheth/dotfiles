#!/bin/bash

PID=$(pgrep wlsunset)

if [ -z "$PID" ]; then
    wlsunset -l -33.9 -L 151.2 -t 3000 &
    notify-send "Night light enabled"
else
    kill "$PID"
    notify-send "Night light disabled"
fi

