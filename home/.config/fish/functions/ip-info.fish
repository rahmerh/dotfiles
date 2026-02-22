function ip-info
    curl -sS ipinfo.io | jq
end
