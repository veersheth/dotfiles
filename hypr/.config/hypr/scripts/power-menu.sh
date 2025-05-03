#!/bin/bash

choice=$(printf "Shutdown\nReboot\nLogout\nLock\nCancel" | wofi --dmenu --width 200 --height 300 --prompt "Power")

case "$choice" in
  Shutdown)
    systemctl poweroff
    ;;
  Reboot)
    systemctl reboot
    ;;
  Logout)
    hyprctl dispatch exit
    ;;
  Lock)
    swaylock
    ;;
  Cancel)
    exit 0
    ;;
esac

