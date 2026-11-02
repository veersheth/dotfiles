#!/usr/bin/env bash

set -euo pipefail

readonly BRIGHTNESS_STEP=5
readonly GAMMA=2.0
readonly BACKLIGHT_CLASS=backlight

usage() {
    printf 'Usage: %s {up|down|idle-dim}\n' "$0" >&2
}

direction="${1:-}"
if (( $# != 1 )); then
    usage
    exit 2
fi
case "$direction" in
    up|down|idle-dim) ;;
    *) usage; exit 2 ;;
esac

for dependency in brightnessctl awk; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing required dependency: %s\n' "$dependency" >&2
        exit 1
    fi
done

# Only inspect the panel backlight. brightnessctl's default device scan also
# probes keyboard and ChromeOS LED devices, which may return intermittent EOF.
current=$(brightnessctl -q -c "$BACKLIGHT_CLASS" get)
max=$(brightnessctl -q -c "$BACKLIGHT_CLASS" max)
if [[ ! "$current" =~ ^[0-9]+$ || ! "$max" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Could not read a valid backlight value (current=%q, max=%q).\n' "$current" "$max" >&2
    exit 1
fi

# Save on every timeout, even when already dim, so resume never restores a
# stale value from an earlier idle cycle. The idle target must never brighten.
if [[ "$direction" == idle-dim ]]; then
    hardware=$((max / 10))
    if (( current < hardware )); then
        hardware=$current
    fi
    brightnessctl -q -c "$BACKLIGHT_CLASS" -s set "$hardware"
    exit 0
fi

# Move in perceptual percentage so each key press feels consistent.
perceptual=$(awk -v current="$current" -v max="$max" -v gamma="$GAMMA" \
    'BEGIN { printf "%.0f", 100 * (current / max) ^ (1 / gamma) }')
if [[ "$direction" == up ]]; then
    perceptual=$((perceptual + BRIGHTNESS_STEP))
else
    perceptual=$((perceptual - BRIGHTNESS_STEP))
fi
(( perceptual < 0 )) && perceptual=0
(( perceptual > 100 )) && perceptual=100

# Convert directly to raw hardware units. Rounding to a whole percentage
# first turns the first step from zero (0.25%) back into zero forever.
hardware=$(awk -v perceptual="$perceptual" -v gamma="$GAMMA" -v max="$max" \
    'BEGIN { printf "%.0f", max * (perceptual / 100) ^ gamma }')

# Also guarantee progress on panels with very few hardware levels.
if [[ "$direction" == up ]] && (( hardware <= current && current < max )); then
    hardware=$((current + 1))
elif [[ "$direction" == down ]] && (( hardware >= current && current > 0 )); then
    hardware=$((current - 1))
fi

brightnessctl -q -c "$BACKLIGHT_CLASS" set "$hardware"
if command -v qs >/dev/null 2>&1; then
    qs ipc call osd brightness >/dev/null 2>&1 || true
fi
