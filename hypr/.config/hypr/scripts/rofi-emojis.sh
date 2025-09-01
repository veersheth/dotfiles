#!/bin/bash

choice=$(cat ~/.config/hypr/scripts/emoji-list | rofi -dmenu -i -p "Emoji")
emoji=$(awk '{print $1}' <<< "$choice")

[[ -n $emoji ]] && wl-copy "$emoji"

