#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

set theme_repo ~/repos/kitty-theme

print_info "Setting kitty theme"

if not test -d "$theme_repo"
    print_info "Cloning theme repo"
    command git clone --depth 1 https://github.com/dexpota/kitty-themes.git "$theme_repo" &>/dev/null
else
    print_info "Updating theme repo"
    command git -C "$theme_repo" pull &>/dev/null
end

mkdir -p ~/dotfiles/home/.config/kitty/themes

cp "$theme_repo/themes/Chalk.conf" ~/dotfiles/home/.config/kitty/themes/theme.conf

print_success Done
