#!/usr/bin/env bash

# Compatibility entry point for the old misspelled filename.
exec "$(dirname -- "$0")/brightness.sh" "$@"
