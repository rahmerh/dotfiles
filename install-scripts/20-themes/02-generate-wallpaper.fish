#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

function make_wallpaper
    set -l width $argv[1]
    set -l height $argv[2]
    set -l out $argv[3]

    set -l bg "#2C2C2C"
    set -l pink "#E85A98"
    set -l tmp (mktemp -d)

    magick -size {$width}x{$height} xc:"$bg" miff:"$tmp/canvas.miff"

    magick -size {$width}x{$height} xc:none -fill "$pink" \
        -draw "polygon 0,0 200,0 500,$height 300,$height" \
        miff:"$tmp/band1.miff"

    magick -size {$width}x{$height} xc:none -fill "$pink" \
        -draw "polygon 300,0 400,0 700,$height 600,$height" \
        miff:"$tmp/band2.miff"

    magick -size {$width}x{$height} xc:none -fill "$pink" \
        -draw "polygon 500,0 600,0 900,$height 800,$height" \
        miff:"$tmp/band3.miff"

    magick "$tmp/canvas.miff" "$tmp/band1.miff" -compose Over -composite miff:"$tmp/step1.miff"
    magick "$tmp/step1.miff" "$tmp/band2.miff" -compose Over -composite miff:"$tmp/step2.miff"
    magick "$tmp/step2.miff" "$tmp/band3.miff" -compose Over -composite "$out"

    rm -rf "$tmp"
end

print_info "Creating wallpapers"

set main_out ~/Pictures/wallpaper-5120x1440.png

make_wallpaper 5120 1440 $main_out
make_wallpaper 2560 1600 ~/Pictures/wallpaper-2560x1600.png
make_wallpaper 2560 1440 ~/Pictures/wallpaper-2560x1440.png

pkill hyprpaper
hyprctl dispatch exec hyprpaper
