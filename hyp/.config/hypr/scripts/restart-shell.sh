#!/usr/bin/env bash

set -u

# Restart the shell processes, then reload the compositor config.
pkill quickshell 2>/dev/null || true
pkill -x hypridle 2>/dev/null || true
sleep 0.5

if ! hyprctl reload; then
    printf 'Hyprland reload failed; restarting the shell processes anyway.\n' >&2
fi

quickshell &
hypridle &
disown -a
sleep 0.5
