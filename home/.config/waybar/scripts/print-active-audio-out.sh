#!/bin/bash

declare -A known_sinks=(
    # Home pc known sinks
    ["audiorelay_Speaker"]="Audiorelay"
    ["alsa_output.pci-0000_00_1f.3.analog-stereo"]="Speakers"
    ["alsa_output.usb-Corsair_CORSAIR_VOID_ELITE_Wireless_Gaming_Dongle-00.analog-stereo"]="Headphones"
    
    # Work laptop known sinks
)

get_sink_name() {
    local sink desc
    sink=$(pactl get-default-sink 2>/dev/null) || return

    desc=$(pactl list sinks |
        awk -v s="$sink" '
            $0 ~ "Name: " s "$" { in_sink=1 }
            in_sink && /Description:/ {
                sub(/^[ \t]*Description: /, "", $0)
                print
                exit
            }
        '
    )

    if [[ -n "${known_sinks[$sink]}" ]]; then
        echo "${known_sinks[$sink]}"
    else
        echo "${desc:-$sink}"
    fi
}

get_sink_name

pactl subscribe \
  | grep --line-buffered -E "Event 'change' on (sink|server)|Event 'new' on sink" \
  | while read -r _; do
        get_sink_name
    done
