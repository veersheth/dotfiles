#!/bin/bash
class=$(hyprctl activewindow | grep -oP '(?<=class: ).*' || echo "")

if [ -z "$class" ]; then
  echo "Desktop"
else
  echo "LOL LOL $class"
fi

