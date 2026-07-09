#!/usr/bin/env bash
transition=1  # default: smooth

case "$1" in
    -i|--instant) transition=0; shift ;;
    -s|--smooth|-t|--transition) transition=1; shift ;;
esac

current=$(brightnessctl get)
max=$(brightnessctl max)
arg="$1"
if [[ "$arg" == +*% ]]; then
    pct="${arg:1:$((${#arg}-2))}"
    target=$((current + max * pct / 100))
elif [[ "$arg" == -*% ]]; then
    pct="${arg:1:$((${#arg}-2))}"
    target=$((current - max * pct / 100))
elif [[ "$arg" == *%+ ]]; then
    pct="${arg%\%+}"
    target=$((current + max * pct / 100))
elif [[ "$arg" == *%- ]]; then
    pct="${arg%\%-}"
    target=$((current - max * pct / 100))
elif [[ "$arg" == *% ]]; then
    pct="${arg%\%}"
    target=$((max * pct / 100))
else
    target="$arg"
fi
[ "$target" -lt 1 ] && target=1
[ "$target" -gt "$max" ] && target=$max
diff=$((target - current))
steps=6
if [ "$transition" -eq 1 ] && [ "$diff" -ne 0 ]; then
    for ((i=1; i<=steps; i++)); do
        val=$((current + diff * i / steps))
        brightnessctl set "$val" >/dev/null
        sleep 0.001
    done
fi
brightnessctl set "$target" >/dev/null
# pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
# notify-send -a "Brightness" -r 91191 -i display-brightness -h int:value:"$pct" -t 1500 "Brightness: ${pct}%"
