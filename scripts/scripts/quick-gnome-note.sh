#!/usr/bin/env bash

alacritty --class "quick-note" \
  --option window.dimensions.columns=80 \
  --option window.dimensions.lines=24 \
  --option window.position.x=100 \
  --option window.position.y=100 \
  -e nvim \
  -c "set autowriteall" \
  -c "set updatetime=1000" \
  -c "autocmd CursorHold,CursorHoldI,TextChanged,TextChangedI <buffer> silent! update" \
  ~/note.md
