#!/usr/bin/env bash

set -euo pipefail

readonly SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
readonly TIMESTAMP=$(date '+%y-%m-%d %H:%M:%S')
readonly SCREENSHOT_FILE="$SCREENSHOT_DIR/Screenshot $TIMESTAMP.png"

usage() {
    printf 'Usage: %s {region|annotate|output|active-output|ocr|lens}\n' "$0" >&2
}

make_temp_file() {
    mktemp "/tmp/screenshot-$1-XXXXXX"
}

mkdir -p "$SCREENSHOT_DIR"

case "${1:-}" in
    region)
        hyprshot -m region -z --raw | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        ;;
    annotate)
        hyprshot -m region -z --raw \
            | satty --filename - --output-filename "$SCREENSHOT_FILE" --copy-command wl-copy
        ;;
    output)
        hyprshot -m output -z --raw | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        ;;
    active-output)
        hyprshot -m output -m active -z --raw | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        ;;
    ocr)
        temp_file=$(make_temp_file ocr)
        trap 'rm -f "$temp_file"' EXIT
        hyprshot -m region -z --raw > "$temp_file"
        tesseract "$temp_file" stdout 2>/dev/null | wl-copy
        ;;
    lens)
        temp_file=$(make_temp_file lens)
        trap 'rm -f "$temp_file"' EXIT
        hyprshot -m region -z --raw > "$temp_file"
        upload_url=$(curl --fail --silent --show-error \
            -F 'reqtype=fileupload' -F 'time=1h' -F "fileToUpload=@$temp_file" \
            https://litterbox.catbox.moe/resources/internals/api.php)
        if [[ ! "$upload_url" =~ ^https?:// ]]; then
            printf 'Screenshot upload failed: %s\n' "$upload_url" >&2
            exit 1
        fi
        xdg-open "https://lens.google.com/uploadbyurl?url=$upload_url"
        ;;
    *)
        usage
        exit 2
        ;;
esac
