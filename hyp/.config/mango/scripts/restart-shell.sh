#!/usr/bin/env bash
set -euo pipefail

qs kill --path "$HOME/.config/quickshell" >/dev/null 2>&1 || true

# Wait for shutdown; force-stop a stuck instance before starting another one.
for _ in {1..20}; do
    pgrep -u "$(id -u)" -x quickshell >/dev/null || break
    sleep 0.1
done
pkill -KILL -u "$(id -u)" -x quickshell 2>/dev/null || true

qs --path "$HOME/.config/quickshell" --daemonize
mmsg dispatch reload_config
