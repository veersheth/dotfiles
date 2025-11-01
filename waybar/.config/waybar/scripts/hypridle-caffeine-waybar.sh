#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
  echo '{"text":"󰾪","class":"running","tooltip":"hypridle running"}'
else
  echo '{"text":"󰅶","class":"stopped","tooltip":"hypridle not running"}'
fi

