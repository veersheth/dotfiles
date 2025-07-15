#!/bin/bash

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
status=$(playerctl status 2>/dev/null)

if [[ "$status" == "Playing" ]]; then
    icon=""  # Pause
elif [[ "$status" == "Paused" ]]; then
    icon=""  # Play
else
    echo '{"text": "", "class": "stopped"}'
    exit
fi

echo "{\"text\": \"  $title - $artist \", \"class\": \"$status\"}"

# #!/bin/bash
#
# artist=$(playerctl metadata artist 2>/dev/null)
# title=$(playerctl metadata title 2>/dev/null)
# status=$(playerctl status 2>/dev/null)
#
# if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
#     icon="⏵"
#     [[ "$status" == "Paused" ]] && icon="⏸"
#     echo "{\"text\": \"$icon $artist - $title\", \"class\": \"$status\"}"
# else
#     echo "{\"text\": \"\", \"class\": \"stopped\"}"
# fi
#

