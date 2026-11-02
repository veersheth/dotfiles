#!/usr/bin/env bash
set -euo pipefail

config="${HOME}/.config/hypr/hyprlock.conf"
selection="${HOME}/.local/state/quickshell/wallpaper.txt"

for command in hyprlock awk mktemp; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'lock.sh: required command missing: %s\n' "$command" >&2
        exit 1
    fi
done

if [[ ! -r "$config" ]]; then
    printf 'lock.sh: Hyprlock config is not readable: %s\n' "$config" >&2
    exit 1
fi

if [[ ! -r "$selection" ]]; then
    printf 'lock.sh: Quickshell wallpaper selection is not readable: %s; using configured background\n' "$selection" >&2
    exec hyprlock --config "$config"
fi

wallpaper=$(<"$selection")
wallpaper=${wallpaper%$'\n'}

if [[ "$wallpaper" == color:\#* ]]; then
    color=${wallpaper#color:#}
    if [[ ! "$color" =~ ^[[:xdigit:]]{6}$ ]]; then
        printf 'lock.sh: invalid Quickshell background color; using configured background\n' >&2
        exec hyprlock --config "$config"
    fi
    lock_image=
    lock_color="rgb($color)"
elif [[ -f "$wallpaper" && -r "$wallpaper" && "$wallpaper" == /* ]]; then
    lock_image=$wallpaper
    lock_color=
else
    printf 'lock.sh: Quickshell wallpaper is not a readable image: %s; using configured background\n' "$wallpaper" >&2
    exec hyprlock --config "$config"
fi

runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
temporary_config=$(mktemp "$runtime_dir/hyprlock.XXXXXX.conf")
trap 'rm -f -- "$temporary_config"' EXIT

LOCK_IMAGE=$lock_image LOCK_COLOR=$lock_color awk '
    /^background[[:space:]]*\{/ { in_background = 1 }
    in_background && /^[[:space:]]*path[[:space:]]*=/ {
        print "    path = " ENVIRON["LOCK_IMAGE"]
        if (ENVIRON["LOCK_COLOR"] != "") print "    color = " ENVIRON["LOCK_COLOR"]
        next
    }
    in_background && /^\}/ { in_background = 0 }
    { print }
' "$config" > "$temporary_config"

hyprlock --config "$temporary_config"
