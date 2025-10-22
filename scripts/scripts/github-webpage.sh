#!/usr/bin/env bash

cd "$(tmux run "echo #{pane_start_path}")" || exit

url=$(git remote get-url origin 2>/dev/null)

if [[ -z "$url" ]]; then
    tmux display-popup -E "echo 'No remote found'; read -n1"
    exit 1
fi

if [[ $url == *github.com* ]]; then
    if [[ $url == git@* ]]; then
        url="${url#git@}"
        url="${url/:/\/}"
        url="https://$url"
    fi
else
    tmux display-popup -E "echo 'This repository is not hosted on GitHub'; read -n1"
    exit 1
fi

# # hope to god this works on EVERY machine one of these HAS to be instlled
# if command -v xclip >/dev/null 2>&1; then
#     echo -n "$url" | xclip -selection clipboard
# elif command -v wl-copy >/dev/null 2>&1; then
#     echo -n "$url" | wl-copy
# elif command -v pbcopy >/dev/null 2>&1; then
#     echo -n "$url" | pbcopy
# else
#     tmux display-popup -E "no supported clipboard tool installed. insert it manually"
#     tmux display-popup -E "
#     echo 'Copied to clipboard:'; 
#     echo '$url'; 
#     sleep 5;
#     "
#     exit 1
# fi

notify-send "URL copied to clipboard" "$url"
echo "$url"
