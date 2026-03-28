#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

function _ensure_cached_winetricks_package \
    --description "Ensure a winetricks package is cached for reuse" \
    --argument-names pkg cache_root

    set pkg_cache "$cache_root/$pkg"
    set installed_marker "$pkg_cache/.install-complete"

    if test -f "$installed_marker"
        print_info "Package '$pkg' already cached."
        return 0
    end

    print_info "Caching winetricks package '$pkg'"

    set tmp_prefix (mktemp -d ~/.cache/tmp-wine-prefix-XXXXXX)

    gum spin --spinner points --title "Booting temp wine prefix..." -- \
        bash -c "WINEPREFIX=$tmp_prefix wineboot -u &>/dev/null"

    gum spin --spinner points --title "Installing '$pkg' into temp folder..." -- \
        bash -c "WINEPREFIX=$tmp_prefix winetricks -q $pkg &>/dev/null"

    if test $status -ne 0
        print_error "Failed to install '$pkg' to cache"
        rm -rf $tmp_prefix
        return 1
    end

    mkdir -p "$cache_root"
    mv "$tmp_prefix" "$pkg_cache"

    touch "$installed_marker"

    print_success "Package '$pkg' successfully cached."
end

function _determine_and_retrieve_exe \
    --argument-names github_repo target
    set exe_urls ( curl -s "https://api.github.com/repos/$github_repo/releases/latest" \
        |  jq -r '.assets[] | select(.name | endswith(".exe")) | "\(.name)|\(.browser_download_url)"')

    if test (count $exe_urls) -eq 0
        print_error "No .exe assets found in $github_repo release"
        return 1
    end

    set selected_entry
    if test (count $exe_urls) -eq 1
        set selected_entry $exe_urls[1]
    else
        print_error "Multiple .exe files found in $github_repo release:"
        for entry in $exe_urls
            print_error "  - $entry"
        end
        print_error "Update script to handle multiple installers."
        return 1
    end

    set selected_name (string split "|" $selected_entry)[1]
    set selected_url (string split "|" $selected_entry)[2]

    curl -L "$selected_url" -o "$target" >/dev/null 2>&1
    if not test -f "$target"
        print_error "Failed to download $selected_name"
        return 1
    end
end

function install_wine_app \
    --description "Install a Wine app in an isolated prefix" \
    --argument-names app_name github_repo winetricks_packages exe_relative_path

    for cmd in wine winetricks jq curl
        if not type -q $cmd
            print_error "$cmd is not installed"
            return 1
        end
    end

    set prefix_path "$HOME/.local/wineprefixes/$app_name"
    set exe_path "$prefix_path/$app_name-installer.exe"
    set installed_marker "$prefix_path/.install-complete"

    if test -f "$installed_marker"
        print_info "App '$app_name' already installed."
        return 0
    end

    print_info "Installing '$app_name' to '$prefix_path'"

    if not test -d "$prefix_path"
        mkdir -p "$prefix_path"
        gum spin --spinner points --title "Booting wine prefix..." -- \
            bash -c "WINEPREFIX='$prefix_path' wineboot -u > /dev/null 2>&1"
    end

    set cache_root ~/.local/wineprefixes/.cache
    for pkg in (string split ' ' -- "$winetricks_packages")
        set pkg_cache "$cache_root/$pkg"

        _ensure_cached_winetricks_package "$pkg" "$cache_root"

        set pkg_marker "$prefix_path/.pkg-$pkg-installed"
        if not test -f "$pkg_marker"
            cp -a "$pkg_cache/." "$prefix_path/"

            gum spin --spinner points --title "Registering '$pkg' in real prefix..." -- \
                bash -c "WINEPREFIX=$prefix_path winetricks -q $pkg >/dev/null 2>&1"

            if test $status -ne 0
                print_error "Failed to install '$pkg' with winetricks"
                return 1
            end

            touch "$pkg_marker"
        else
            print_info "Skipping '$pkg', already registered in prefix"
        end
    end

    _determine_and_retrieve_exe $github_repo $exe_path

    gum spin --spinner points --title "Running installer at '$exe_path'..." -- \
        bash -c "WINEPREFIX=$prefix_path wine $exe_path &>/dev/null"
    if test $status -ne 0
        print_error "Installer for $app_name failed"
        return 1
    end

    touch "$installed_marker"

    print_success "Successfully installed '$app_name' to '$prefix_path'"
end
