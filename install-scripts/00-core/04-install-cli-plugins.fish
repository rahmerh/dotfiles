#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

print_info "Installing/updating fisher"

if ! type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher install jorgebucaran/fisher &>/dev/null
else
    fisher update jorgebucaran/fisher &>/dev/null
end

print_success "Fisher done"

print_info "Installing Yazi plugins"

set -l plugins \
    yazi-rs/plugins:no-status \
    yazi-rs/plugins:smart-enter \
    yazi-rs/plugins:git \
    yazi-rs/plugins:jump-to-char

for plugin in $plugins
    ya pkg add $plugin
end

ya pkg install

print_success "Yazi done"
