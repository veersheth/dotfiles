#!/bin/bash

artist=$(playerctl --player=spotify metadata artist 2>/dev/null)
title=$(playerctl --player=spotify metadata title 2>/dev/null)
status=$(playerctl --player=spotify status 2>/dev/null)

if [[ "$status" == "Playing" ]]; then
    icon=""
elif [[ "$status" == "Paused" ]]; then
    icon=""
else
    echo '{"text": "", "class": "stopped"}'
    exit
fi

echo "{\"text\": \"  $title - $artist \", \"class\": \"$status\"}"

