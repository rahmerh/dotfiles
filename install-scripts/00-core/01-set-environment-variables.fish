#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/machine-type-utils.fish

print_info "Setting environment variables"

set -Ux XDG_CONFIG_HOME ~/.config
set -Ux VISUAL nvim
set -Ux EDITOR nvim

set -gx QT_QPA_PLATFORMTHEME qt5ct
set -gx QT_STYLE_OVERRIDE qt5ct
set -gx XDG_CURRENT_DESKTOP KDE

fish_add_path ~/.local/bin

if mt_is_work
    set -Ux CHROME_EXECUTABLE /usr/bin/google-chrome-stable

    fish_add_path ~/.pub-cache/bin
    fish_add_path ~/go/bin
end

print_success Done
