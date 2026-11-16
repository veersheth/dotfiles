#!/usr/bin/env bash

rc_socket=$1
mount_dir=$2
script_path=$3
icon_path=$4
runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$UID}
tray_dir=$(mktemp -d "$runtime_dir/mount-onedrive-tray.XXXXXX") || exit 1
tray_fifo=$tray_dir/commands
mkfifo "$tray_fifo" || exit 1
exec 3<>"$tray_fifo"

shell_quote() {
    local value=${1//\'/\'\\\'\'}
    printf "'%s'" "$value"
}

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name=OneDrive --icon="$icon_path" "$@" >/dev/null 2>&1 || true
}

open_command="xdg-open $(shell_quote "$mount_dir")"
script_command=$(shell_quote "$script_path")
actions="Open OneDrive!$open_command|Restart mount!$script_command restart|Stop mount!$script_command stop"

yad --indicator --image="$icon_path" --text="OneDrive: checking status" \
    --listen --menu="Status: checking!true|$actions" <&3 >/dev/null 2>&1 &
yad_pid=$!

cleanup() {
    printf 'quit\n' >&3 2>/dev/null || true
    kill "$yad_pid" 2>/dev/null || true
    exec 3>&-
    rm -f "$tray_fifo"
    rmdir "$tray_dir" 2>/dev/null || true
}
trap 'exit 0' INT TERM
trap cleanup EXIT

previous_uploads=0
previous_errors=0
last_event="Mounted"
last_menu=

while kill -0 "$yad_pid" 2>/dev/null; do
    vfs_stats=$(rclone rc --unix-socket "$rc_socket" vfs/stats fs=onedrive: 2>/dev/null)
    if [[ -z "$vfs_stats" ]]; then
        state="Status unavailable"
        detail="Rclone control is not responding"
        tooltip="OneDrive: $state"
    else
        read -r queued uploading errors < <(jq -r '[.diskCache.uploadsQueued // 0, .diskCache.uploadsInProgress // 0, .diskCache.erroredFiles // 0] | @tsv' <<< "$vfs_stats")
        core_stats=$(rclone rc --unix-socket "$rc_socket" core/stats 2>/dev/null) || core_stats='{}'
        read -r transfers speed < <(jq -r '[(.transferring // [] | length), ([.transferring[]?.speedAvg // 0] | add // 0 | floor)] | @tsv' <<< "$core_stats")

        if (( errors > 0 )); then
            state="Upload error"
        elif (( uploading > 0 )); then
            state="Uploading"
        elif (( queued > 0 )); then
            state="Waiting to upload"
        elif (( transfers > 0 )); then
            state="Downloading"
        else
            state="Up to date"
        fi

        if (( errors > previous_errors )); then
            last_event="Upload error"
            notify --urgency=critical "OneDrive upload failed" "$errors cached file(s) have upload errors."
        elif (( previous_uploads > 0 && queued == 0 && uploading == 0 && errors == 0 )); then
            last_event="Uploads complete"
            notify "OneDrive uploads complete" "All queued files have uploaded."
        elif (( previous_uploads == 0 && queued + uploading > 0 )); then
            last_event="Uploading"
        fi

        previous_uploads=$((queued + uploading))
        previous_errors=$errors
        detail="Queued: $queued, active uploads: $uploading, transfers: $transfers"
        tooltip="OneDrive: $state"
        if (( transfers > 0 )); then
            speed_label=$(numfmt --to=iec --suffix=B/s "$speed" 2>/dev/null || printf '%s B/s' "$speed")
            tooltip="$tooltip ($speed_label)"
        fi
    fi

    menu="Status: $state!true|$detail!true|Last event: $last_event!true|$actions"
    if [[ "$menu" != "$last_menu" ]]; then
        printf 'menu:%s\ntooltip:%s\n' "$menu" "$tooltip" >&3
        last_menu=$menu
    fi
    sleep 3
done
