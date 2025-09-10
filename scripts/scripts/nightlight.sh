#!/bin/bash

STATE_FILE="/tmp/hyprsunset_state"

# Check desktop environment
if [[ "$XDG_CURRENT_DESKTOP" == "Hyprland" || -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    if [[ -f "$STATE_FILE" ]]; then
        STATE=$(cat "$STATE_FILE")
    else
        STATE="OFF"
    fi

    turn_off() {
        pkill -9 hyprsunset 2>/dev/null
    }

    notify_short() {
        notify-send -t 500 "Sunset" "$1"
    }

    case "$STATE" in
        "OFF")
            hyprsunset -t 6000 &
            echo "6000" > "$STATE_FILE"
            ;;
        "6000")
            turn_off
            hyprsunset -t 4000 &
            echo "4000" > "$STATE_FILE"
            ;;
        "4000")
            turn_off
            hyprsunset -t 2000 &
            echo "2000" > "$STATE_FILE"
            ;;
        "2000")
            turn_off
            echo "OFF" > "$STATE_FILE"
            ;;
        *)
            turn_off
            echo "OFF" > "$STATE_FILE"
            ;;
    esac

elif [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
    bash -c 'if [[ $(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled) == "true" ]]; then
        gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false
    else
        gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    fi'

else
    notify-send -t 2000 "Sunset" "This script only supports Hyprland and GNOME"
fi

