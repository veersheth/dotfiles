#!/bin/bash

WALLPAPER_DIR=~/wallpapers
SELECTED=$(find ~/wallpapers/* -type f | wofi --show dmenu --prompt "pick wallpaper")

[ -z "$SELECTED" ] && exit 0

hyprctl hyprpaper wallpaper ",$SELECTED" &

notify-send -t 500 "Wallpaper changed" "$SELECTED"
