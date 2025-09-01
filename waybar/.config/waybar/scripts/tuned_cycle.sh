#!/usr/bin/env bash

current=$(tuned-adm active | awk -F': ' '{print $2}')
case "$current" in
    desktop)   next="powersave" ;;
    balanced-battery)  next="desktop" ;;
    powersave) next="balanced-battery" ;;
    *) next="balanced-battery" ;;
esac

tuned-adm profile "$next"

