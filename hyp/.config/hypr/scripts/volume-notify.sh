#!/usr/bin/env bash

wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "$1"
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 # unmute

vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
pct=$(echo "$vol" | awk '{print int($2*100)}')

if echo "$vol" | grep -q MUTED; then
    # notify-send -a "Volume" -r 91190 -i audio-volume-muted -t 1500 "Volume Muted"
else
    # notify-send -a "Volume" -r 91190 -i audio-volume-high -h int:value:"$pct" -t 1500 "Volume: ${pct}%"
fi
