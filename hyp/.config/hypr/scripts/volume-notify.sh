#!/usr/bin/env bash
# Usage:
#   volume-notify.sh 5%+                  — adjust sink volume
#   volume-notify.sh --mute [sink|source] — toggle mute (default: sink)

if [[ "$1" == "--mute" ]]; then
    device="${2:-@DEFAULT_AUDIO_SINK@}"
    wpctl set-mute "$device" toggle

    if [[ "$device" == "@DEFAULT_AUDIO_SOURCE@" ]]; then
        label="Microphone"; icon_on="microphone-sensitivity-high"; icon_off="microphone-disabled"
    else
        label="Volume"; icon_on="audio-volume-high"; icon_off="audio-volume-muted"
    fi

    if wpctl get-volume "$device" | grep -q MUTED; then
        # notify-send -a "$label" -r 91190 -i "$icon_off" -t 1500 "$label Muted"
        :
    else
        # notify-send -a "$label" -r 91190 -i "$icon_on" -t 1500 "$label Unmuted"
        :
    fi
else
    wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "$1"
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0  # unmute on volume change

    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    pct=$(echo "$vol" | awk '{print int($2*100)}')

    if echo "$vol" | grep -q MUTED; then
        # notify-send -a "Volume" -r 91190 -i audio-volume-muted -t 1500 "Volume Muted"
        :
    else
        # notify-send -a "Volume" -r 91190 -i audio-volume-high -h int:value:"$pct" -t 1500 "Volume: ${pct}%"
        :
    fi
fi
