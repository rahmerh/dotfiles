#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

print_info "Creating wallpaper"

set bg "#2C2C2C"
set pink "#E85A98"
set out ~/Pictures/wallpaper.png
set tmp (mktemp -d)

magick -size 5120x1440 xc:"$bg" miff:"$tmp/canvas.miff"

magick -size 5120x1440 xc:none -fill "$pink" -draw "polygon 0,0 200,0 500,1440 300,1440" miff:"$tmp/band1.miff"
magick -size 5120x1440 xc:none -fill "$pink" -draw "polygon 300,0 400,0 700,1440 600,1440" miff:"$tmp/band2.miff"
magick -size 5120x1440 xc:none -fill "$pink" -draw "polygon 500,0 600,0 900,1440 800,1440" miff:"$tmp/band3.miff"

magick "$tmp/canvas.miff" "$tmp/band1.miff" -compose Over -composite miff:"$tmp/step1.miff"
magick "$tmp/step1.miff" "$tmp/band2.miff" -compose Over -composite miff:"$tmp/step2.miff"
magick "$tmp/step2.miff" "$tmp/band3.miff" -compose Over -composite "$out"

pkill hyprpaper
hyprctl dispatch exec hyprpaper
