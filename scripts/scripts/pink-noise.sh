#!/bin/bash

if pgrep -x play >/dev/null 2>&1; then
    pkill -x play
else
    play -nq synth pinknoise vol 0.10 &
fi

