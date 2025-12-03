#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/machine-type-utils.fish

if mt_is_work
    print_info "Not configuring audio relay on a work machine."
    return
end

print_info "Configuring audio relay"

if ! type -q ufw
    print_error "UFW not installed, fix this script to use your current firewall."
    return
end

if ! string match -q "Status: active" (sudo ufw status 2>/dev/null | head -n 1)
    print_warn "UFW is not active."
    return
else
    set rules (sudo ufw status 2>/dev/null | string match '*59100*')
    if test -z "$rules"
        print_info "Setting firewall rules so the app can connect"
        sudo ufw allow 59100:59103/tcp 2>/dev/null
        sudo ufw allow 59100:59103/udp 2>/dev/null
        sudo ufw reload 2>/dev/null
    end
end

set prefs_path ~/.java/.userPrefs/com/azefsw/audioconnect/prefs.xml

if not test -f $prefs_path
    print_warn "prefs.xml not found. Make sure AudioRelay has been launched at least once."
    return
end

print_info "Apply default settings"

function ensure_entry
    set -l key $argv[1]
    set -l value $argv[2]

    if grep -q -- "<entry[^>]*key=\"$key\"" $prefs_path
        env VAL="$value" perl -i -0777 -pe 's/(<entry[^>]*key="'"$key"'"[^>]*value=")[^"]*(")/$1.$ENV{VAL}.$2/eg' -- "$prefs_path"
    else
        if grep -q -- "</map>" $prefs_path
            sed -i "/<\/map>/i\\
    <entry key=\"$key\" value=\"$value\"/>" $prefs_path
        else
            sed -i "/<\/root>/i\\
    <entry key=\"$key\" value=\"$value\"/>" $prefs_path
        end
    end
end

ensure_entry device_capture_id AudioRelay-Virtual-Speaker
ensure_entry device_render_id AudioRelay-Virtual-Mic
ensure_entry dark_mode true

print_success Done
