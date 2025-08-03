#!/bin/bash

choice=$(printf "Cancel\nLock\nLogout\nShutdown\nReboot" | wofi --dmenu --width 200 --height 300 --prompt "Power")

case "$choice" in
  Cancel)
    exit 0
    ;;
  Lock)
      hyprlock
    ;;
  Logout)
    hyprctl dispatch exit
    ;;
  Shutdown)
    systemctl poweroff
    ;;
  Reboot)
    systemctl reboot
    ;;
esac

