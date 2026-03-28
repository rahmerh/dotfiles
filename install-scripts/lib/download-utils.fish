#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

function download_favicon
    set -l domain $argv[1]
    set -l out_path $argv[2]

    if test -z "$domain" -o -z "$out_path"
        echo "Usage: download_favicon <domain> <output_path>"
        return 1
    end

    if test -f $out_path
        return 0
    end

    set -l url "https://$domain/favicon.ico"
    mkdir -p (dirname $out_path)

    curl -sL $url -o $out_path
end
