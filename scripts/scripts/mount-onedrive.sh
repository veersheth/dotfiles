#!/usr/bin/env bash

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}"
mount_dir="$HOME/OneDrive"
lock_file="$runtime_dir/mount-onedrive-${UID}.lock"
pid_file="$runtime_dir/mount-onedrive-${UID}.pid"
log_file="${XDG_STATE_HOME:-$HOME/.local/state}/mount-onedrive.log"
rc_socket="$runtime_dir/mount-onedrive-${UID}.sock"
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/rclone"
service_file="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/mount-onedrive-script.service"
script_path=$(readlink -f "$0")
mount_pid=
stopping=0

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name=OneDrive --icon=folder-remote "$@" >/dev/null 2>&1 || true
}

process_start_time() {
    awk '{ print $22 }' "/proc/$1/stat" 2>/dev/null
}

# The start time prevents a stale PID file from pointing at an unrelated process.
managed_pid() {
    local pid start_time
    [[ -r "$pid_file" ]] || return 1
    read -r pid start_time < "$pid_file" || return 1
    [[ "$pid" =~ ^[0-9]+$ && -n "$start_time" ]] || return 1
    [[ "$(process_start_time "$pid")" == "$start_time" ]] || return 1
    printf '%s\n' "$pid"
}

stop_mount() {
    stopping=1
    if [[ -n "$mount_pid" ]]; then
        kill "$mount_pid" 2>/dev/null || true
    fi
}

run_mount() {
    local connected=0 status

    # Keep the lock for the lifetime of the mount. The rclone child inherits it.
    exec 9>"$lock_file" || return 1
    if ! flock -n 9; then
        echo "OneDrive mount is already running."
        return 0
    fi
    printf '%s %s\n' "$$" "$(process_start_time "$$")" > "$pid_file"
    trap 'rm -f "$pid_file"' EXIT
    trap stop_mount INT TERM

    if mountpoint -q "$mount_dir"; then
        notify "OneDrive is already mounted" "$mount_dir"
        return 0
    fi

    # A dead rclone process can leave a broken FUSE mount in the mount table.
    if findmnt --mountpoint "$mount_dir" >/dev/null 2>&1; then
        if ! fusermount3 -u "$mount_dir"; then
            notify --urgency=critical "OneDrive mount failed" "Could not clear the stale mount at $mount_dir"
            return 1
        fi
    fi

    if ! mkdir -p "$mount_dir"; then
        notify --urgency=critical "OneDrive mount failed" "Could not create $mount_dir"
        return 1
    fi

    # Only the process holding our lock may replace an abandoned control socket.
    rm -f -- "$rc_socket"
    notify "Mounting OneDrive" "$mount_dir"
    rclone mount onedrive: "$mount_dir" \
        --rc --rc-addr "unix://$rc_socket" \
        --cache-dir "$cache_root" \
        --vfs-cache-mode full \
        --vfs-cache-max-age 720h \
        --vfs-cache-max-size 20G \
        --dir-cache-time 5m \
        --poll-interval 1m \
        --vfs-write-back 10s &
    mount_pid=$!

    while kill -0 "$mount_pid" 2>/dev/null; do
        if mountpoint -q "$mount_dir"; then
            connected=1
            notify "OneDrive mounted" "$mount_dir"
            break
        fi
        sleep 0.5
    done

    wait "$mount_pid"
    status=$?
    if (( stopping )); then
        wait "$mount_pid" 2>/dev/null || true
        notify "OneDrive unmounted" "$mount_dir"
        return 0
    elif (( status == 0 )); then
        notify "OneDrive unmounted" "$mount_dir"
    elif (( connected )); then
        notify --urgency=critical "OneDrive mount stopped" "rclone exited with status $status."
    else
        notify --urgency=critical "OneDrive mount failed" "rclone exited with status $status."
    fi
    return "$status"
}

start_mount() {
    local pid attempt
    if pid=$(managed_pid); then
        echo "OneDrive mount is already running (PID $pid)."
        return 0
    fi
    if mountpoint -q "$mount_dir"; then
        echo "OneDrive is already mounted by another process."
        return 0
    fi
    mkdir -p "$runtime_dir" "${log_file%/*}" || return 1
    # An older script can release its FUSE mount just before rclone releases
    # the inherited lock. Wait for that shutdown to finish before launching.
    for ((attempt = 0; attempt < 60; attempt++)); do
        if flock -n "$lock_file" true; then
            break
        fi
        sleep 0.5
    done
    if ! flock -n "$lock_file" true; then
        echo "OneDrive is still shutting down." >&2
        return 1
    fi
    if [[ -f "$service_file" ]]; then
        systemctl --user start mount-onedrive-script.service || return 1
    else
        if ! systemd-run --user --collect --unit="mount-onedrive-$$-$(date +%s%N)" \
            --setenv="PATH=$PATH" --setenv="HOME=$HOME" \
            --setenv="XDG_RUNTIME_DIR=$runtime_dir" \
            bash -c 'exec "$1" run >>"$2" 2>&1' bash "$script_path" "$log_file"; then
            return 1
        fi
    fi
    for ((attempt = 0; attempt < 120; attempt++)); do
        if mountpoint -q "$mount_dir"; then
            echo "OneDrive mounted at $mount_dir (log: $log_file)."
            return 0
        fi
        if (( attempt > 4 )) && ! managed_pid >/dev/null; then
            echo "OneDrive failed to mount. Recent log output:" >&2
            tail -n 10 "$log_file" >&2
            return 1
        fi
        sleep 0.5
    done
    echo "OneDrive is still starting (log: $log_file)."
}

stop_managed_mount() {
    local pid attempt source fstype
    if ! pid=$(managed_pid); then
        read -r source fstype < <(findmnt --mountpoint "$mount_dir" --noheadings --output SOURCE,FSTYPE 2>/dev/null)
        if [[ "$source" == "onedrive:" && "$fstype" == "fuse.rclone" ]]; then
            echo "Stopping existing OneDrive rclone mount."
            fusermount3 -u "$mount_dir" || return 1
            for ((attempt = 0; attempt < 60; attempt++)); do
                if ! findmnt --mountpoint "$mount_dir" >/dev/null 2>&1; then
                    echo "OneDrive stopped."
                    return 0
                fi
                sleep 0.5
            done
            echo "Timed out waiting for OneDrive to unmount." >&2
            return 1
        fi
        echo "OneDrive mount is not running."
        return 0
    fi
    kill "$pid" || return 1
    for ((attempt = 0; attempt < 60; attempt++)); do
        if ! managed_pid >/dev/null; then
            echo "OneDrive stopped."
            return 0
        fi
        sleep 0.5
    done
    echo "Timed out waiting for OneDrive to stop." >&2
    return 1
}

show_status() {
    local pid
    pid=$(managed_pid) || pid=
    if mountpoint -q "$mount_dir"; then
        echo "OneDrive is mounted at $mount_dir${pid:+ (PID $pid)}."
    elif findmnt --mountpoint "$mount_dir" >/dev/null 2>&1; then
        echo "OneDrive has a stale FUSE mount at $mount_dir."
        return 1
    elif [[ -n "$pid" ]]; then
        echo "OneDrive mount is starting (PID $pid)."
    else
        echo "OneDrive is not mounted."
        return 1
    fi
}

confirm() {
    local answer
    read -r -p "$1 [yes/no] " answer
    [[ "$answer" == yes ]]
}

configure_baobab() {
    local baobab_path schema_file current uri updated
    command -v baobab >/dev/null 2>&1 || return 0
    command -v gsettings >/dev/null 2>&1 || return 0

    if ! gsettings list-keys org.gnome.baobab.preferences >/dev/null 2>&1; then
        baobab_path=$(readlink -f "$(command -v baobab)")
        schema_file=$(find "${baobab_path%/bin/baobab}/share/gsettings-schemas" \
            -name org.gnome.baobab.gschema.xml -print -quit 2>/dev/null)
        [[ -n "$schema_file" ]] || return 0
        export GSETTINGS_SCHEMA_DIR="${schema_file%/*}"
    fi

    current=$(gsettings get org.gnome.baobab.preferences excluded-uris) || return 1
    uri=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).as_uri())' "$mount_dir") || return 1
    updated=$(python3 -c '
import ast, sys
value, uri = sys.argv[1:]
items = [] if value == "@as []" else ast.literal_eval(value)
if uri not in items:
    items.append(uri)
print(repr(items))
' "$current" "$uri") || return 1
    gsettings set org.gnome.baobab.preferences excluded-uris "$updated" || return 1
    echo "Disk Usage Analyzer will exclude $mount_dir from home scans."
}

setup_mount() {
    local missing=() command_name
    for command_name in rclone fusermount3 flock findmnt systemd-run systemctl jq python3; do
        command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
    done
    if (( ${#missing[@]} )); then
        printf 'Install these commands first: %s\n' "${missing[*]}" >&2
        return 1
    fi
    confirm "Set up OneDrive, exclude it from Disk Usage Analyzer, and enable mounting at login?" || return 0
    if ! rclone listremotes | grep -Fxq 'onedrive:'; then
        echo "Create an rclone remote named onedrive."
        rclone config || return 1
    fi
    if ! rclone listremotes | grep -Fxq 'onedrive:'; then
        echo "The onedrive: remote is still missing." >&2
        return 1
    fi
    rclone lsd onedrive: >/dev/null || return 1
    mkdir -p "$runtime_dir" "$mount_dir" "${log_file%/*}" || return 1
    configure_baobab || return 1
    if [[ -e "$service_file" ]]; then
        if ! grep -Fq "ExecStart=$script_path run" "$service_file"; then
            echo "Refusing to overwrite existing $service_file." >&2
            return 1
        fi
    else
        mkdir -p "${service_file%/*}" || return 1
        cat > "$service_file" <<EOF
[Unit]
Description=OneDrive rclone mount
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
Environment="PATH=$PATH"
ExecStart=$script_path run
Restart=on-failure
RestartSec=10s
StandardOutput=append:$log_file
StandardError=append:$log_file

[Install]
WantedBy=default.target
EOF
    fi
    systemctl --user daemon-reload || return 1
    systemctl --user enable mount-onedrive-script.service || return 1
    start_mount
}

wait_for_uploads() {
    local stats queued active errors data_path meta_path stable=0 attempt
    for ((attempt = 0; attempt < 450; attempt++)); do
        stats=$(rclone rc --unix-socket "$rc_socket" vfs/stats fs=onedrive: 2>/dev/null) || {
            echo "Cannot read the OneDrive upload queue; preserving cache." >&2
            return 1
        }
        read -r queued active errors data_path meta_path < <(jq -r '[.diskCache.uploadsQueued, .diskCache.uploadsInProgress, .diskCache.erroredFiles, .diskCache.path, .diskCache.pathMeta] | @tsv' <<< "$stats")
        if [[ ! "$queued" =~ ^[0-9]+$ || ! "$active" =~ ^[0-9]+$ || ! "$errors" =~ ^[0-9]+$ ]]; then
            echo "Invalid VFS cache status; preserving cache." >&2
            return 1
        fi
        if [[ "$data_path" != "$cache_root/vfs/onedrive" || "$meta_path" != "$cache_root/vfsMeta/onedrive" ]]; then
            echo "Unexpected VFS cache location; preserving cache." >&2
            return 1
        fi
        if (( errors > 0 )); then
            echo "$errors cached file(s) have upload errors; preserving cache." >&2
            return 1
        fi
        if (( queued == 0 && active == 0 )); then
            ((stable += 1))
            if (( stable >= 3 )); then
                rclone lsd onedrive: >/dev/null || {
                    echo "OneDrive is unreachable; preserving cache." >&2
                    return 1
                }
                return 0
            fi
        else
            stable=0
            echo "Waiting for uploads: $queued queued, $active active."
        fi
        sleep 2
    done
    echo "Timed out waiting for uploads; preserving cache." >&2
    return 1
}

clean_mount() {
    local force="$1"
    if [[ "$force" == force ]]; then
        confirm "Force clean? This can permanently discard files not yet uploaded to OneDrive." || return 0
    else
        confirm "Close OneDrive files first. Wait for uploads, then delete local cache and restart? Cloud files will not be deleted." || return 0
        if ! rclone rc --unix-socket "$rc_socket" vfs/stats fs=onedrive: >/dev/null 2>&1; then
            stop_managed_mount || return 1
            start_mount || return 1
        fi
        wait_for_uploads || return 1
        stop_managed_mount || return 1
        # A second mount replays any writes left in the cache during shutdown.
        start_mount || return 1
        wait_for_uploads || return 1
    fi

    stop_managed_mount || return 1
    if findmnt --mountpoint "$mount_dir" >/dev/null 2>&1; then
        echo "OneDrive is still mounted; preserving cache." >&2
        return 1
    fi
    # These are rclone's VFS data and metadata for the onedrive: remote only.
    rm -rf -- "$cache_root/vfs/onedrive" "$cache_root/vfsMeta/onedrive" || return 1
    rm -f -- "$pid_file" "$rc_socket"
    mkdir -p "${log_file%/*}" || return 1
    : > "$log_file"
    start_mount
}

case "${1:-run}" in
    run)     mkdir -p "$runtime_dir" && run_mount ;;
    start)   start_mount ;;
    stop)    stop_managed_mount ;;
    restart) stop_managed_mount && start_mount ;;
    status)  show_status ;;
    logs)    if [[ -f "$log_file" ]]; then tail -n 50 "$log_file"; else echo "No OneDrive log yet."; fi ;;
    setup)   setup_mount ;;
    clean)
        case "${2:-}" in
            '')      clean_mount safe ;;
            --force) clean_mount force ;;
            *)       echo "Usage: $0 clean [--force]" >&2; exit 2 ;;
        esac
        ;;
    help|-h|--help)
        echo "Usage: $0 [run|start|stop|restart|status|logs|setup|clean [--force]]"
        ;;
    *)
        echo "Usage: $0 [run|start|stop|restart|status|logs|setup|clean [--force]]" >&2
        exit 2
        ;;
esac
