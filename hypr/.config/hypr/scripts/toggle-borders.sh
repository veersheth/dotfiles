#!/bin/bash

# Get the current border size
border_size=$(hyprctl getoption general:border_size -j | jq '.int')

if [ "$border_size" -eq 0 ]; then
    hyprctl keyword general:border_size 1
    hyprctl keyword general:gaps_out 12
else
    hyprctl keyword general:border_size 0
    hyprctl keyword general:gaps_out 0
fi

