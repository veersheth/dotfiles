#!/bin/bash

# Kill previous processes
pkill waybar
pkill swaync
pkill hyprpaper
pkill hypridle

sleep 0.2

# Log environment and check if commands are available
{
    echo "PATH: $PATH"
    command -v hyprpaper
    command -v waybar
    command -v swaync
    command -v hypridle
} > ~/hyprland_env.log

# Launch each program and check if it fails
run_with_notify() {
    app_name="$1"
    log_file="$2"
    shift 2

    "$@" &> "$log_file" &
    pid=$!
    sleep 0.2
    if ! kill -0 "$pid" 2>/dev/null; then
        notify-send "⚠️ $app_name failed to start" "Check $log_file for details."
    fi
}

run_with_notify "Hyprpaper"   ~/hyprpaper_startup.log   nixGL hyprpaper
run_with_notify "Waybar"      ~/waybar_startup.log      nixGL waybar
run_with_notify "SwayNC"      ~/swaync_startup.log      nixGL swaync
run_with_notify "Hypridle"    ~/hypridle_startup.log    nixGL hypridle

