#!/usr/bin/env bash

options=" Lock\n Sleep\n Restart\n Shutdown\n Logout"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power")

case "$chosen" in
    " Lock")    
        hyprlock ;;   
    " Sleep")   
        systemctl suspend ;;
    " Restart") 
        systemctl reboot ;;
    " Shutdown") 
        systemctl poweroff ;;
    " Logout")  
        hyprctl dispatch exit ;;  
esac

