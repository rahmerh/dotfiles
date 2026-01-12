#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

print_info "Configuring ssh"

set ssh_dir "$HOME/.ssh"
set config_file "$ssh_dir/config"

set -l candidates
for f in "$ssh_dir"/*
    test -f "$f"; or continue
    string match -q -- "*.pub" "$f"; and continue

    set bn (basename "$f")
    switch $bn
        case config known_hosts authorized_keys
            continue
    end

    string match -q -- "*.old" "$f"; and continue
    string match -q -- "*.bak" "$f"; and continue
    string match -q -- "*.tmp" "$f"; and continue

    if test -f "$f.pub"
        set candidates $candidates "$f"
    end
end

if test (count $candidates) -eq 0
    set -l key_path "$ssh_dir/id_ed25519"

    print_info "No SSH keys found. Generating a new ed25519 key: $key_path"
    ssh-keygen -t ed25519 -a 64 -f "$key_path"
else
    print_info "Default SSH key already generated"
end

if test -e "$config_file"
    print_info "SSH config already exists: $config_file"
else
    print_info "Creating SSH config: $config_file"

    printf "Host *\n    AddKeysToAgent yes\n" >"$config_file"
end

print_success Done
