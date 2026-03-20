#!/usr/bin/env fish
source install-scripts/library/download-utils.fish
source install-scripts/library/print-utils.fish

set -l icon_dir ~/.local/share/icons

print_info "Downloading icons"

download_favicon nexusmods.com /tmp/nexusmods.ico
magick /tmp/nexusmods.ico "$icon_dir/nexusmods.png" &>/dev/null

print_info "Moving icons from dotfiles"

cp ~/dotfiles/install-scripts/assets/icons/screenshot.png "$icon_dir"

print_success Done
