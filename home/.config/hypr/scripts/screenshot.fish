#!/usr/bin/env fish

set -l screenshots_dir "$HOME/Pictures/Screenshots"
set -l timestamp_now (date +'%Y-%m-%d_%H-%M-%S')
set -l file "$screenshots_dir/$timestamp_now.png"

mkdir -p "$screenshots_dir"

function usage
    echo "Usage: screenshot.fish <save|copy|both>"
    exit 1
end

if test (count $argv) -ne 1
    usage
end

set action $argv[1]

set geom (slurp -b 00000088 -s 00000000 -w 0)
if test -z "$geom"
    exit 0
end

switch $action
    case save
        grim -g "$geom" "$file"

        set -l clicked (notify-send \
            -i "$HOME/.local/share/icons/screenshot.png" \
            --action=default=Open \
            "Screenshot saved" \
            "$file")

        if test "$clicked" = default
            feh "$file" &
        end
    case copy
        grim -g "$geom" - | wl-copy --type image/png

        notify-send \
            -i "$HOME/.local/share/icons/screenshot.png" \
            "Screenshot copied" \
            "Copied to clipboard"
    case both
        grim -g "$geom" "$file"

        wl-copy --type image/png <"$file"

        set -l clicked (notify-send \
            -i "$HOME/.local/share/icons/screenshot.png" \
            --action=default=Open \
            "Screenshot saved + copied" \
            "$file")

        if test "$clicked" = default
            feh "$file" &
        end
    case '*'
        usage
end
