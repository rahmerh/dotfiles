#!/usr/bin/env fish

hyprctl reload

pkill hyprpaper
hyprctl dispatch exec hyprpaper

pkill waybar
hyprctl dispatch exec "waybar -s ~/.config/waybar/bars/main/style.css -c ~/.config/waybar/bars/main/config.jsonc"

pkill mako
hyprctl dispatch exec mako

fish -c ~/.config/hypr/scripts/set-wallpaper.fish
