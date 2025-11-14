#!/bin/bash

audiorelay="audiorelay_Speaker"
speakers="alsa_output.pci-0000_00_1f.3.analog-stereo"
headphones="alsa_output.usb-Corsair_CORSAIR_VOID_ELITE_Wireless_Gaming_Dongle-00.analog-stereo"

current_sink=$(pactl get-default-sink)

if [[ "$current_sink" == "$audiorelay" ]]; then
    pactl set-default-sink "$speakers"
elif [[ "$current_sink" == "$speakers" ]]; then
    pactl set-default-sink "$headphones"
elif [[ "$current_sink" == "$headphones" ]]; then
    pactl set-default-sink "$audiorelay"
fi
