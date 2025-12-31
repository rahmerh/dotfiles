#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

function make_wallpaper
    set -l width $argv[1]
    set -l height $argv[2]
    set -l out $argv[3]

    set -l bg "#1A1A1A"
    set -l pink "#E85A98"
    set -l tmp (mktemp -d)

    magick -size {$width}x{$height} xc:"$bg" miff:"$tmp/canvas.miff"

    magick -size {$width}x{$height} xc:none -fill "$pink" \
        -draw "polygon 0,0 100,0 100,$height 0,$height" \
        miff:"$tmp/band1.miff"

    magick "$tmp/canvas.miff" "$tmp/band1.miff" -compose Over -composite "$out"

    rm -rf "$tmp"
end

print_info "Creating wallpapers"

# Just some resolutions of monitors I use.
make_wallpaper 5120 1440 ~/Pictures/wallpaper-5120x1440.png
make_wallpaper 2560 1600 ~/Pictures/wallpaper-2560x1600.png
make_wallpaper 2560 1440 ~/Pictures/wallpaper-2560x1440.png

print_info Done

~/.config/hypr/scripts/set-wallpaper.fish
