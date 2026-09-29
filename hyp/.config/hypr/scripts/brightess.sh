#!/usr/bin/env bash

STEP=5
GAMMA=2.0

direction="$1"

current=$(brightnessctl get)
max=$(brightnessctl max)

# Convert current hardware brightness to perceptual percentage
perceptual=$(awk \
    -v current="$current" \
    -v max="$max" \
    -v gamma="$GAMMA" \
    'BEGIN {
        printf "%.0f", 100 * (current / max) ^ (1 / gamma)
    }')

case "$direction" in
    up)
        perceptual=$((perceptual + STEP))
        ;;
    down)
        perceptual=$((perceptual - STEP))
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
        ;;
esac

# Clamp to 0-100
(( perceptual < 0 )) && perceptual=0
(( perceptual > 100 )) && perceptual=100

# Convert perceptual percentage back to hardware brightness
hardware=$(awk \
    -v perceptual="$perceptual" \
    -v gamma="$GAMMA" \
    'BEGIN {
        printf "%.0f", 100 * (perceptual / 100) ^ gamma
    }')

brightnessctl set "${hardware}%"
qs ipc call osd brightness
