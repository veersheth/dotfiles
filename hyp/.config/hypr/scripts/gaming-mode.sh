#!/usr/bin/env bash
STATE_FILE="/tmp/hyprland-gaming-mode-active-80491374012830120380129830218"

if [ ! -f "$STATE_FILE" ]; then

  notify-send 'Starting Game Mode' -t 2

  # Check power status
  CHARGING=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo "1")
  BATTERY=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "100")
  WARN=""

  if [ "$CHARGING" = "0" ] && [ "$BATTERY" -lt 20 ]; then
    WARN="Not charging and battery at ${BATTERY}%"
  elif [ "$CHARGING" = "0" ]; then
    WARN="Not plugged in (battery at ${BATTERY}%)"
  elif [ "$BATTERY" -lt 40 ]; then
    WARN="Battery at ${BATTERY}%, connect charger"
  fi
  if [ -n "$WARN" ]; then
    CHOICE=$(echo -e "Okay\nCancel" | rofi)
    if [ "$CHOICE" != "Okay" ]; then
      exit 0
    fi
  fi

  # Enter gaming mode
  touch "$STATE_FILE"
 
  # hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "10" }))'
  powerprofilesctl set performance
  gamemoded -r &
  hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } }, misc = { vfr = false } })'
  steam steam://open/bigpicture &

else
  # Exit gaming mode
  rm "$STATE_FILE"
  powerprofilesctl set balanced
  pkill gamemoded
  hyprctl reload


  steam -shutdown &
  sleep 15
  # Only force-kill if Steam is still running after graceful shutdown
  pkill -f steam 2>/dev/null
fi
