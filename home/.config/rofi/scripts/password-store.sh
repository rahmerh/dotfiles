#!/usr/bin/env bash

store_dir=${1:-$HOME/.password-store}

if [[ ! -d "$store_dir" ]]; then
    notify-send "Password store" "No password store found at $store_dir"
    exit 1
fi

mapfile -t entries < <(
    fd \
        --base-directory "$store_dir" \
        --type f \
        --extension gpg \
        --format '{.}' |
        sort
)

if (( ${#entries[@]} == 0 )); then
    exit 0
fi

selection=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Password")

[[ -n "$selection" ]] || exit 0

if ! pass show --clip "$selection"; then
    notify-send "Password store" "Failed to copy $selection"
    exit 1
fi
