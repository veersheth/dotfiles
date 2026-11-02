#!/usr/bin/env bash

set -euo pipefail

current=$(gsettings get org.gnome.desktop.interface color-scheme)
case "$current" in
    "'prefer-dark'") next=prefer-light ;;
    *) next=prefer-dark ;;
esac

gsettings set org.gnome.desktop.interface color-scheme "$next"
