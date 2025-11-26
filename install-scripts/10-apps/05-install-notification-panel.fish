#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/git-utils.fish

print_info "Installing notification panel"

mkdir -p ~/projects

clone rahmerh/notification-panel ~/projects/notification-panel

cd ~/projects/notification-panel

make install >/dev/null
