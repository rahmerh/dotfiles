#!/usr/bin/env bash

entries=$(
    while IFS= read -r vault; do
        pass-cli item list \
            --filter-type login \
            --filter-state active \
            --sort-by alphabetic-asc \
            --output json \
            "$vault" |
            jq -r --arg vault "$vault" '
                .items[] |
                ["\(.title) [\($vault)]", "pass://\(.share_id)/\(.id)/password"] |
                @tsv
            '
    done < <(pass-cli vault list --output json | jq -r '.vaults[].name')
)

selection=$(printf '%s\n' "$entries" | rofi -dmenu -i -p "Password" -display-columns 1)

[[ -n "$selection" ]] || exit 0

password=$(pass-cli item view "${selection#*$'\t'}") || exit 1

printf '%s' "$password" | wl-copy --sensitive --paste-once
