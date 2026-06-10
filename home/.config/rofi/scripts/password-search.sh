#!/usr/bin/env bash

passwords_file="$HOME/.cache/password-store/entries.json"
pass_cli="$HOME/.local/bin/pass-cli"
notification_icon="$HOME/Pictures/icons/password-key.png"

if [[ ! -r "$passwords_file" ]]; then
    notify-send --icon="$notification_icon" \
        "Password search" "No password cache found."
    exit 1
fi

if [[ -z "${1:-}" ]]; then
    jq -r '
        sort_by(.title | ascii_downcase)[] |
        [.share_id, .id, .title] |
        @tsv
    ' "$passwords_file" |
        while IFS=$'\t' read -r share_id item_id title; do
            printf '%s\t%s\0display\x1f%s\x1fmeta\x1f%s\n' \
                "$share_id" "$item_id" "$title" "$title"
        done
    exit 0
fi

IFS=$'\t' read -r share_id item_id <<<"$1"

password=$("$pass_cli" item view \
        --share-id "$share_id" \
        --item-id "$item_id" \
        --field password)

if [[ -z "$password" ]]; then
    notify-send --icon="$notification_icon" \
        "Password search" "Could not retrieve password"
    exit 1
fi

wl-copy -o --sensitive "$password"
