#!/usr/bin/env bash
set -euo pipefail

require() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    }
}

for cmd in grim slurp wl-copy wayfreeze; do
    require "$cmd"
done

readonly SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
readonly SCREENSHOT_FILE="$SCREENSHOT_DIR/Screenshot $(date '+%y-%m-%d %H:%M:%S').png"

freeze_pid=

cleanup() {
    if [[ -n ${freeze_pid:-} ]] && kill -0 "$freeze_pid" 2>/dev/null; then
        kill "$freeze_pid" 2>/dev/null || true
        wait "$freeze_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

freeze_screen() {
    wayfreeze --hide-cursor &
    freeze_pid=$!
    sleep 0.1
}

region_geometry() {
    slurp -d
}

mkdir -p "$SCREENSHOT_DIR"

case "${1:-}" in
    region)
        freeze_screen
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        grim -g "$geometry" - | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        ;;
    annotate)
        require satty
        freeze_screen
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        grim -g "$geometry" - |
            satty --filename - --output-filename "$SCREENSHOT_FILE" --copy-command wl-copy
        ;;
    output)
        freeze_screen
        monitor=$(mmsg get cursorpos 2>/dev/null | jq -r '.monitor // empty' || true)
        if [[ -n $monitor ]]; then
            grim -o "$monitor" - | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        else
            grim - | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        fi
        ;;
    ocr)
        require tesseract
        freeze_screen
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        grim -g "$geometry" "$SCREENSHOT_FILE"
        tesseract "$SCREENSHOT_FILE" stdout 2>/dev/null | wl-copy
        ;;
    lens)
        require curl
        require xdg-open
        freeze_screen
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        grim -g "$geometry" "$SCREENSHOT_FILE"
        upload_url=$(curl --fail --silent --show-error \
            -F 'reqtype=fileupload' -F 'time=1h' -F "fileToUpload=@$SCREENSHOT_FILE" \
            https://litterbox.catbox.moe/resources/internals/api.php)
        [[ $upload_url == https://* ]] || exit 1
        xdg-open "https://lens.google.com/uploadbyurl?url=$upload_url"
        ;;
    *)
        printf 'Usage: %s {region|annotate|output|ocr|lens}\n' "$0" >&2
        exit 2
        ;;
esac
