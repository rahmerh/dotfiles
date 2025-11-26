#!/usr/bin/env fish

function clone
    if test (count $argv) -lt 1
        print_info "Usage: clone <repo> [outdir]"
        return 1
    end

    set repo $argv[1]
    set outdir ""

    if test (count $argv) -ge 2
        set outdir $argv[2]
    end

    if test -d $outdir
        print_info "Project already cloned, exiting."
        return 0
    end

    if string match -qr '^[^/]+/[^/]+$' -- $repo
        set repo "https://github.com/$repo"
    end

    set repo_path (string match -r "(github\.com[:/])([^ ]+)" $repo)[3]

    if test -z "$repo_path"
        print_error "Error: unsupported repo format. Only GitHub URLs are supported."
        return 1
    end

    set clone_with_ssh false
    if test -f ~/.ssh/id_rsa -o -f ~/.ssh/id_ed25519
        ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
        if test $status -eq 0
            set clone_with_ssh true
        end
    end

    set ssh_url "git@github.com:$repo_path"
    set https_url "https://github.com/$repo_path"

    if test "$clone_with_ssh" = true
        git clone $ssh_url $outdij
    else
        git clone $https_url $outdir
    end
end
