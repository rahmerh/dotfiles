#!/usr/bin/env fish

pkill swaybg
~/.config/niri/scripts/set-wallpaper.fish &

pkill waybar
setsid -f waybar

pkill mako
setsid -f mako
