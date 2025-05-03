#!/bin/bash

mkdir -p ~/Pictures/Screenshots

FILENAME="Screenshot $(date '+%Y-%m-%d %H-%M').png"
FULL_PATH="$HOME/Pictures/Screenshots/$FILENAME"
TEMP_FILE="$HOME/screenshot_temp.png"

grimshot save area "$TEMP_FILE"

if [ $? -eq 0 ]; then
  cp "$TEMP_FILE" "$FULL_PATH"
  wl-copy < "$TEMP_FILE"
  rm "$TEMP_FILE"
  notify-send "Screenshot saved as $FILENAME and copied to clipboard"
else
  notify-send "Error taking screenshot" -u critical
fi
