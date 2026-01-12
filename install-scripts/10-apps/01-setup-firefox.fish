#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

print_info "Configuring firefox"

set profile_dir (find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default-release" | head -n 1)
if not test -d "$profile_dir"
    print_error "firefox profile not found. Launch firefox once and retry."
    return 1
end

function set_pref --argument key value
    set prefs "$profile_dir/prefs.js"
    sed -i "/user_pref(\"$key\"/d" "$prefs"
    echo "user_pref(\"$key\", $value);" >>"$prefs"
end

function install_extension --argument extension_name
    set tmpfile (mktemp /tmp/ext.XXXXXX.xpi)
    set extensions_dir "$profile_dir/extensions"
    set cache_file "$extensions_dir/installed-extensions-cache.json"

    mkdir -p "$extensions_dir" &>/dev/null

    if not test -e "$cache_file"
        echo "{}" >"$cache_file"
    end

    set ext_id (jq -r --arg slug "$extension_name" '.[$slug] // empty' "$cache_file")
    if test -n "$ext_id" -a -e "$extensions_dir/$ext_id.xpi"
        print_info "Extension $extension_name already installed as $ext_id, skipping"
        return
    end

    curl -sLo "$tmpfile" "https://addons.mozilla.org/firefox/downloads/latest/$extension_name/latest.xpi"

    set ext_id (unzip -p "$tmpfile" manifest.json | jq -r '.browser_specific_settings.gecko.id')
    if test -z "$ext_id"
        print_error "Failed to extract extension ID for $extension_name, skipping"
        return
    end

    jq --arg slug "$extension_name" --arg id "$ext_id" '. + {($slug): $id}' "$cache_file" >/tmp/new-cache.json
    mv /tmp/new-cache.json "$cache_file" &>/dev/null

    cp "$tmpfile" "$extensions_dir/$ext_id.xpi"

    print_success "Installed $extension_name. Enable it in firefox manually."
end

# Preferences
set_pref "privacy.clearOnShutdown.cookies" false
set_pref "privacy.clearOnShutdown.history" true
set_pref "privacy.clearOnShutdown.sessions" false
set_pref "privacy.clearOnShutdown.cache" true
set_pref "privacy.clearOnShutdown.offlineApps" true
set_pref "privacy.clearOnShutdown.siteSettings" false
set_pref "network.cookie.lifetimePolicy" 0
set_pref "browser.sessionstore.resume_from_crash" false
set_pref "toolkit.legacyUserProfileCustomizations.stylesheets" true

# Extensions
install_extension sponsorblock
install_extension return-youtube-dislikes
install_extension control-panel-for-youtube
install_extension proton-pass
install_extension ublock-origin

print_success Done
