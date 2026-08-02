#!/usr/bin/env bash

FILE="$HOME/Pictures/Screenshots/Screenshot $(date "+%y-%m-%d %H:%M:%S").png"

case "$1" in
    region)
        hyprshot -m region -z --raw | tee "$FILE" | wl-copy --type image/png
        ;;
    annotate)
        hyprshot -m region -z --raw | satty --filename - --output-filename "$FILE" --copy-command wl-copy
        ;;
    ocr)
        TMPFILE=$(mktemp /tmp/screenshot-ocr-XXXXXX.png)
        hyprshot -m region -z --raw > "$TMPFILE"
        tesseract "$TMPFILE" stdout 2>/dev/null | wl-copy
        rm -f "$TMPFILE"
        ;;
    output)
        hyprshot -m output -z --raw | tee "$FILE" | wl-copy --type image/png
        ;;
    *)
        echo "Usage: $0 {region|annotate|output|ocr}"
        exit 1
        ;;
esac

