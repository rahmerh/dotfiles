#!/usr/bin/env bash

pkill swaybg &>/dev/null

wallpapers=("$HOME/Pictures/wallpapers/*")

if set -q wp[1]
    swaybg -i "$wp[1]" -m fill >/dev/null 2>&1 &
else
    notify-send "Missing wallpaper" "No wallpaper found in ~/Pictures (wallpaper.*)"
end
