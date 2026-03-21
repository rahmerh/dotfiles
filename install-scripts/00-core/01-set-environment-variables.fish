#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/machine-type-utils.fish

print_info "Setting environment variables"

set -Ux XDG_CONFIG_HOME ~/.config
set -Ux VISUAL nvim
set -Ux EDITOR nvim
set -Ux MANPAGER "bat -plman"

set -Ux QT_QPA_PLATFORM wayland
set -Ux LIBDECOR_DISABLE 1

if mt_is_work
    set -Ux CHROME_EXECUTABLE /usr/bin/google-chrome-stable
end

print_success Done
