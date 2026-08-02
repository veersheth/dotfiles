#!/usr/bin/env bash

# tmux sessionizer
hyprctl dispatch 'hl.dsp.exec_cmd("kitty -e /home/veer/dotfiles/scripts/scripts/tmux-sessionizer --init", { workspace = "1" })'

# spotatui
hyprctl dispatch 'hl.dsp.exec_cmd("kitty -e spotatui", { workspace = "6" })'

# browser
hyprctl dispatch 'hl.dsp.exec_cmd("firefox", { workspace = "2" })'
