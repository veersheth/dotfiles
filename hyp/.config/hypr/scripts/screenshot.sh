#!/usr/bin/env bash

FILE="$HOME/Pictures/Screenshots/Screenshot $(date "+%y-%m-%d %H:%M:%S").png"

case "$1" in
    region)
        hyprshot -m region -z --raw | tee "$FILE" | wl-copy --type image/png
        ;;
    annotate)
        hyprshot -m region -z --raw | satty --filename - --output-filename "$FILE" --copy-command wl-copy
        ;;
    output)
        hyprshot -m output -z --raw | tee "$FILE" | wl-copy --type image/png
        ;;
    *)
        echo "Usage: $0 {region|annotate|output}"
        exit 1
        ;;
esac

