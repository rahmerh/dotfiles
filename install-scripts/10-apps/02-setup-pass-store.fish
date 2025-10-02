#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/prompt-utils.fish

mkdir -p ~/.gnupg
if not test -f ~/.gnupg/gpg.conf
    echo "use-agent
personal-digest-preferences SHA512
cert-digest-algo SHA512
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed" >~/.gnupg/gpg.conf
    chmod 600 ~/.gnupg/gpg.conf
end

if ! test -d ~/.password-store/.git
    print_info "Password store not initialized, starting setup."
    print_info "Please input your password store git url:"
    set password_store_git_url (gum input --placeholder "Insert git url")
    git clone $password_store_git_url ~/.password-store &>/dev/null

    printf "#!/bin/sh\ngit push origin master > /dev/null 2>&1\n" >~/.password-store/.git/hooks/post-commit
    chmod +x ~/.password-store/.git/hooks/post-commit

    if read_confirm "Do you want to import your gpg key? (Select no if it's already imported)"
        set keyfile (gum file $HOME)
        gpg --import $keyfile
    end

    set existing_keys (gpg --list-keys --with-colons 2> /dev/null | grep '^fpr' | cut -d: -f10)
    set options
    for fpr in $existing_keys
        set email (gpg --list-keys --with-colons $fpr | awk -F: -v fpr=$fpr 'BEGIN {found=0} /^fpr:/ {found=($10==fpr)} /^uid:/ && found { print $10; exit }' | grep -oE '<.*>' | tr -d '<>')
        set -a options "$fpr ($email)"
    end

    print_info "Select the gpg key to use with this store."
    set selection (gum choose $options)

    set GPG_KEY_FINGERPRINT (string match -r '^[A-F0-9]+' -- "$selection")
    pass init $GPG_KEY_FINGERPRINT
else
    print_info "Password store already setup, skipping."
end

if ! test -e ~/.librewolf/native-messaging-hosts/passff.json
    curl -sSL https://codeberg.org/PassFF/passff-host/releases/download/latest/install_host_app.sh | bash -s -- librewolf &>/dev/null
end

print_success Done
