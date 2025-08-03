#!/bin/bash

if pgrep hyprsunset &>/dev/null; then
  pkill hyprsunset
else
  hyprsunset &
  hyprsunset --temperature 3000
fi
