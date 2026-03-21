#!/usr/bin/env fish

pkill swaybg >/dev/null 2>&1

set wp ~/Pictures/wallpaper.*

if set -q wp[1]
    swaybg -i "$wp[1]" -m fill >/dev/null 2>&1 &
else
    notify-send "Missing wallpaper" "No wallpaper found in ~/Pictures (wallpaper.*)"
end
