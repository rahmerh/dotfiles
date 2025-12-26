#!/usr/bin/env fish

if not type -q openrgb
    exit 127
end

function set_color_for_all_devices --description "Set all OpenRGB devices to a color using Direct (preferred) or Static"
    set -l color $argv[1]
    if test -z "$color"
        echo "Usage: set_color_for_all_devices RRGGBB" >&2
        return 1
    end

    set color (string replace -r '^#' '' -- $color)

    set -l dev_ids
    set -l dev_names
    set -l dev_modes

    set -l cur_id ""
    set -l cur_name ""
    set -l cur_modes ""

    while read -l line
        if string match -rq '^[0-9]+: ' -- $line
            if test -n "$cur_id"
                set -a dev_ids "$cur_id"
                set -a dev_names "$cur_name"
                set -a dev_modes "$cur_modes"
            end

            set cur_id (string replace -r '^([0-9]+): .*' '$1' -- $line)
            set cur_name (string replace -r '^[0-9]+: ' '' -- $line)
            set cur_modes ""
            continue
        end

        if string match -rq '^\s*Modes:\s' -- $line
            set cur_modes (string replace -r '^\s*Modes:\s*' '' -- $line)
            continue
        end
    end

    if test -n "$cur_id"
        set -a dev_ids "$cur_id"
        set -a dev_names "$cur_name"
        set -a dev_modes "$cur_modes"
    end

    for i in (seq (count $dev_ids))
        set -l id $dev_ids[$i]
        set -l name $dev_names[$i]
        set -l modes $dev_modes[$i]

        set -l picked_mode ""

        string match -rq '(^|[[:space:]])Direct($|[[:space:]])' -- $modes; and set picked_mode Direct
        if test -z "$picked_mode"
            string match -rq '(^|[[:space:]])Static($|[[:space:]])' -- $modes; and set picked_mode Static
        end

        if test -n "$picked_mode"
            echo "Setting color on device $id: $name ($picked_mode)"
            openrgb -d $id -m $picked_mode -c $color -b 100 &>/dev/null
        end
    end
end

openrgb -l 2>/dev/null | set_color_for_all_devices FF00C:

if type -q razer-cli
    razer-cli --dpi 7000
end
