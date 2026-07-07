#!/usr/bin/env bash
# Renders a minimal analog clock to a PNG for hyprlock's image widget.
# Requires: imagemagick

OUT="/tmp/hyprlock-clock.png"
S=400          # canvas size (px)
C=200          # center

IM=$(command -v magick || command -v convert)

HOUR=$(date +%-I)
MIN=$(date +%-M)
HA=$(( (HOUR % 12) * 30 + MIN / 2 ))   # hour hand angle
MA=$(( MIN * 6 ))                      # minute hand angle

# point on circle: pt <angle> <radius>  ->  "x,y"
pt() {
    awk -v a="$1" -v r="$2" -v c="$C" \
        'BEGIN { rad = (a - 90) * atan2(0, -1) / 180;
                 printf "%.2f,%.2f", c + r * cos(rad), c + r * sin(rad) }'
}

# Tick marks: bold at 12/3/6/9, hairline elsewhere
MAJOR=""; MINOR=""
for i in $(seq 0 11); do
    a=$(( i * 30 ))
    p1=$(pt "$a" 168); p2=$(pt "$a" 184)
    if (( i % 3 == 0 )); then
        MAJOR+="line $p1 $p2 "
    else
        MINOR+="line $p1 $p2 "
    fi
done

HP=$(pt "$HA" 92)      # hour hand tip
MP=$(pt "$MA" 142)     # minute hand tip
HT=$(pt $(( HA + 180 )) 18)   # small tail behind center
MT=$(pt $(( MA + 180 )) 18)

"$IM" -size ${S}x${S} xc:none \
    -stroke "rgba(255,255,255,0.28)" -strokewidth 1.5 -fill none \
    -draw "$MINOR" \
    -stroke "rgba(255,255,255,0.85)" -strokewidth 4 \
    -draw "stroke-linecap round $MAJOR" \
    -stroke "rgba(255,255,255,0.95)" -strokewidth 11 \
    -draw "stroke-linecap round line $HT $HP" \
    -stroke "rgba(255,255,255,0.75)" -strokewidth 6 \
    -draw "stroke-linecap round line $MT $MP" \
    -stroke none -fill "rgba(255,255,255,1)" \
    -draw "circle $C,$C $((C + 7)),$C" \
    "$OUT"

echo "$OUT"
