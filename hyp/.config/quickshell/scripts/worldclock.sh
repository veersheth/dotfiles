#!/usr/bin/env bash
# Usage: worldclock.sh <IANA-timezone>
# Outputs: HH MM SS  in the given timezone, for the world clock widget.
TZ="$1" date "+%H %M %S"
