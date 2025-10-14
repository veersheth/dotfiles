#!/usr/bin/env bash
PLAYERCTL=$(command -v playerctl || echo /usr/bin/playerctl)

artist=$("$PLAYERCTL" metadata artist 2>/dev/null)
title=$("$PLAYERCTL" metadata title 2>/dev/null)

if [ -n "$artist" ] && [ -n "$title" ]; then
  printf '%s - %s\n' "$artist" "$title"
elif [ -n "$title" ]; then
  printf '%s\n' "$title"
else
  printf 'No media\n'
fi
