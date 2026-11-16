#!/usr/bin/env bash
set -euo pipefail

# Prefer installed commands. The Nix store fallback keeps screenshots working
# until grim and slurp are added to the system profile.
resolve_tool() {
    local name=$1 candidate
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return
    fi
    for candidate in /nix/store/*-"$name"-*/bin/"$name"; do
        if [[ -x $candidate ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done
    printf 'Missing %s; install it for Mango screenshots.\n' "$name" >&2
    exit 1
}

GRIM=$(resolve_tool grim)
readonly GRIM
readonly SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
readonly SCREENSHOT_FILE="$SCREENSHOT_DIR/Screenshot $(date '+%y-%m-%d %H:%M:%S').png"

region_geometry() {
    local slurp
    slurp=$(resolve_tool slurp)
    "$slurp" -d
}

make_temp_file() {
    mktemp --suffix=.png "/tmp/screenshot-$1-XXXXXX"
}

mkdir -p "$SCREENSHOT_DIR"

case "${1:-}" in
    region)
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        "$GRIM" -g "$geometry" - | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        ;;
    annotate)
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        "$GRIM" -g "$geometry" - |
            satty --filename - --output-filename "$SCREENSHOT_FILE" --copy-command wl-copy
        ;;
    output)
        monitor=$(mmsg get cursorpos 2>/dev/null | jq -r '.monitor // empty' || true)
        if [[ -n $monitor ]]; then
            "$GRIM" -o "$monitor" - | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        else
            "$GRIM" - | tee "$SCREENSHOT_FILE" | wl-copy --type image/png
        fi
        ;;
    ocr|lens)
        geometry=$(region_geometry)
        [[ -n $geometry ]] || exit 0
        temp_file=$(make_temp_file "$1")
        trap 'rm -f "$temp_file"' EXIT
        "$GRIM" -g "$geometry" "$temp_file"
        if [[ $1 == ocr ]]; then
            tesseract "$temp_file" stdout 2>/dev/null | wl-copy
        else
            upload_url=$(curl --fail --silent --show-error \
                -F 'reqtype=fileupload' -F 'time=1h' -F "fileToUpload=@$temp_file" \
                https://litterbox.catbox.moe/resources/internals/api.php)
            [[ $upload_url == https://* ]] || exit 1
            xdg-open "https://lens.google.com/uploadbyurl?url=$upload_url"
        fi
        ;;
    *)
        printf 'Usage: %s {region|annotate|output|ocr|lens}\n' "$0" >&2
        exit 2
        ;;
esac
