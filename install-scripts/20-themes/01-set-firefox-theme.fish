#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

set theme_repo ~/repos/firefox-theme

print_info "Setting firefox theme"

if not test -d "$theme_repo"
    print_info "Cloning theme repo"
    command git clone https://github.com/cascadefox/cascade.git "$theme_repo" &>/dev/null
else
    print_info "Updating theme repo"
    command git -C "$theme_repo" pull &>/dev/null
end

set profile_dir (find ~/.mozilla/firefox -maxdepth 1 -type d -name '*.default-release' | head -n 1)
if not test -d "$profile_dir"
    print_error "Profile not found. Launch firefox at least once."
    return 1
end

cp -r "$theme_repo/chrome" "$profile_dir"

print_success Done
