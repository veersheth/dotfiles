#!/bin/bash

# Check if redshift is running
if pgrep -x "redshift" > /dev/null
then
    # If redshift is running, kill the process (turn off night light)
    pkill redshift
    echo "Night Light turned off"
else
    # If redshift is not running, start it (turn on night light)
    redshift -O 4000
    echo "Night Light turned on"
fi

