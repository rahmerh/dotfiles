#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

print_info "Stow dotfiles"

stow home

cd system/

sudo stow --target=/ sddm

print_success Done
