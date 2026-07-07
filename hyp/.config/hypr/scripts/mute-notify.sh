#!/usr/bin/env bash
wpctl set-mute "$1" toggle

if [ "$1" = "@DEFAULT_AUDIO_SINK@" ]; then
    label="Volume"; icon_on="audio-volume-high"; icon_off="audio-volume-muted"
else
    label="Microphone"; icon_on="microphone-sensitivity-high"; icon_off="microphone-disabled"
fi

if wpctl get-volume "$1" | grep -q MUTED; then
    # notify-send -a "$label" -r 91190 -i "$icon_off" -t 1500 "$label Muted"
else
    # notify-send -a "$label" -r 91190 -i "$icon_on" -t 1500 "$label Unmuted"
fi
