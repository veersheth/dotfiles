#!/usr/bin/env bash
set -euo pipefail

if [[ -z ${NIRI_SOCKET:-} ]]; then
    for socket in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/niri."${WAYLAND_DISPLAY:-wayland-1}".*.sock; do
        if [[ -S $socket ]]; then
            export NIRI_SOCKET=$socket
            break
        fi
    done
fi

case ${1:-} in
    watch) exec niri msg --json event-stream ;;
    focus)
        # Index is relative to the focused output, so focus the target output first.
        niri msg action focus-monitor "$2"
        exec niri msg action focus-workspace "$3"
        ;;
esac
