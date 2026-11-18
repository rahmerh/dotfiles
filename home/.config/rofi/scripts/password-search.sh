#!/usr/bin/env bash

# Rofi script mode over the login list proton-pass-sync caches (titles and ids
# only). Secrets are fetched from pass-cli for the chosen entry only.
#   Enter  copy password    Alt+U  copy username    Alt+T  copy TOTP code
#   Alt+R  refresh the list in the background

passwords_file="$HOME/.cache/proton-pass/entries.json"
notification_icon="$HOME/Pictures/icons/password-key.png"

notify() {
    notify-send --app-name="Proton Pass" --icon="$notification_icon" "$@"
}

list_entries() {
    printf '\0use-hot-keys\x1ftrue\n'
    printf '\0message\x1fEnter password · Alt+U username · Alt+T TOTP · Alt+R refresh\n'

    jq -r '
        map(select(
            .state == "Active" and
            .item_type == "login" and
            (.title | type == "string") and
            (.share_id | type == "string") and
            (.id | type == "string")
        )) |
        sort_by(.title | ascii_downcase)[] |
        [.title, .share_id, .id] |
        @tsv
    ' "$passwords_file" |
        while IFS=$'\t' read -r entry_title share_id item_id; do
            printf '%s\0info\x1f%s\t%s\n' "$entry_title" "$share_id" "$item_id"
        done
}

# Copies a field; prints nothing, so rofi closes.
copy() {
    local label=$1 value=$2

    if [[ -z $value ]]; then
        notify "Password search" "No $label for $title"
        exit 1
    fi

    wl-copy -o --sensitive "$value"
    notify "Copied $label" "$title"
}

if [[ ! -r $passwords_file ]]; then
    notify "Password search" "No password cache found."
    exit 1
fi

case "${ROFI_RETV:-0}" in
    0)
        list_entries
        exit 0
        ;;
    12)
        systemctl --user start --no-block proton-pass-sync.service
        notify "Password search" "Refreshing the login list"
        exit 0
        ;;
esac

# Typed text that matches no entry carries no info.
[[ -n ${ROFI_INFO:-} ]] || exit 0

IFS=$'\t' read -r share_id item_id <<<"$ROFI_INFO"
title=$1
item=(--share-id "$share_id" --item-id "$item_id")

case "$ROFI_RETV" in
    1)
        copy password "$(pass-cli item view "${item[@]}" --field password)"
        ;;
    10)
        username=$(pass-cli item view "${item[@]}" --field username 2>/dev/null)
        [[ -n $username ]] || username=$(pass-cli item view "${item[@]}" --field email 2>/dev/null)
        copy username "$username"
        ;;
    11)
        copy "TOTP code" "$(pass-cli item totp "${item[@]}" 2>/dev/null | grep -oE '\b[0-9]{6,8}\b' | head -n 1)"
        ;;
esac
