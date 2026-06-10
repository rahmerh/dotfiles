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
        [.title, .share_id, .id] |
        @tsv
    ' "$passwords_file" |
        while IFS=$'\t' read -r title share_id item_id; do
            printf '%s\t%s\t%s\0display\x1f%s\n' \
                "$title" "$share_id" "$item_id" "$title"
        done
    exit 0
fi

IFS=$'\t' read -r _ share_id item_id <<<"$1"

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
