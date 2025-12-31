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

for line in (hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width)x\(.height)"')
    set name (echo $line | awk '{print $1}')
    set res (echo $line | awk '{print $2}')

    set wp "$base_dir/wallpaper-$res.png"

    if test -f "$wp"
        hyprctl hyprpaper preload "$wp" >/dev/null
        hyprctl hyprpaper wallpaper "$name,$wp" >/dev/null
    else
        if not contains -- "$res" $missing_resolutions
            set missing_resolutions $missing_resolutions $res
            notify-send "Missing wallpaper" "No wallpaper found for $res ($wp)"
        end
    end
end
