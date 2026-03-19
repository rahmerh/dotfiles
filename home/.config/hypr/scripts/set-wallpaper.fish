#!/usr/bin/env fish

set base_dir ~/Pictures

pkill hyprpaper >/dev/null
if test $status -ne 0
    echo "hyprpaper was not running"
end

hyprctl dispatch exec hyprpaper >/dev/null
if test $status -ne 0
    echo "Failed to exec hyprpaper"
    exit 1
end

sleep 0.3

set wp ~/Pictures/wallpaper.*

if set -q wp[1]
    hyprctl hyprpaper preload "$wp[1]" >/dev/null
    hyprctl hyprpaper wallpaper ",$wp[1]" >/dev/null
else
    notify-send "Missing wallpaper" "No wallpaper found in ~/Pictures (wallpaper.*)"
end
