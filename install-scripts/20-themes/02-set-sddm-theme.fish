#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

set -l theme_repo ~/repos/sddm-theme
set -l theme_dir where_is_my_sddm_theme
set -l target_dir /usr/share/sddm/themes/$theme_dir
set -l src_dir $theme_repo/$theme_dir

print_info "Setting sddm theme"

if not test -d "$theme_repo"
    print_info "Cloning theme repo"
    command git clone https://github.com/stepanzubkov/where-is-my-sddm-theme.git "$theme_repo" &>/dev/null
else
    print_info "Updating theme repo"
    command git -C "$theme_repo" pull &>/dev/null
end

if not test -d "$src_dir"
    print_error "Theme directory not found: $src_dir"
    exit 1
end

print_info "Copying theme to '$target_dir'"

command sudo mkdir -p "$target_dir"
command sudo cp -a "$src_dir"/. "$target_dir"/
command sudo cp ~/Pictures/wallpaper-5120x1440.png "$target_dir/wallpaper.png"

set -l conf "$target_dir/theme.conf"
if not test -f "$conf"
    print_error "Configuration file '$conf' not found, exiting..."
    exit 1
end

print_info "Configuring theme"

command sudo sed -i -E "s;^passwordCursorColor=.*;passwordCursorColor=#E85A98;" "$conf"
command sudo sed -i -E "s;^passwordFontSize=.*;passwordFontSize=80;" "$conf"
command sudo sed -i -E "s;^cursorBlinkAnimation=.*;cursorBlinkAnimation=true;" "$conf"
command sudo sed -i -E "s;^background=.*;background=wallpaper.png;" "$conf"

print_success Done
