#!/usr/bin/env fish

for monitor in $(hyprctl monitors | grep 'Monitor' | awk '{ print $2 }')
    hyprctl hyprpaper preload~/Pictures/wallpaper.png
    hyprctl hyprpaper wallpaper "$monitor,~/Pictures/wallpaper.png"
end
