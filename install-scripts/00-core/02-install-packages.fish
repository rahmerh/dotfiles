#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/machine-type-utils.fish

print_info "Updating all packages and installing defaults"

if not type -q yay
    set yay_dir (mktemp -d -t yay-XXXX)
    cd $yay_dir
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
    tar zxvf yay.tar.gz
    cd yay
    makepkg --syncdeps --rmdeps --install --noconfirm
end

# Core CLI tools
set core_packages \
    neovim \
    fish \
    kitty \
    bat \
    lsd \
    ripgrep \
    jq \
    stow \
    pv \
    gnupg \
    tealdeer \
    neofetch \
    7zip \
    yazi \
    wine \
    imagemagick \
    bc \
    pastel

# GUI/system tools
set gui_packages \
    firefox \
    firewalld \
    lazygit \
    pulsemixer \
    rofi \
    feh \
    docker \
    docker-compose \
    nvidia-container-toolkit \
    nwg-displays \
    keychain \
    pinta \
    ripdrag

# Hyprland stack
set hyprland_packages \
    hyprland \
    hyprpaper \
    hyprpicker \
    hyprlock \
    hypridle \
    waybar \
    mako \
    grim \
    slurp \
    wl-clipboard \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-termfilechooser-hunkyburrito-git

# Fonts
set font_packages \
    ttf-jetbrains-mono-nerd

# Dev tools
set dev_packages \
    npm \
    go \
    qt5-tools \
    luarocks

set personal_packages \
    openrazer-meta \
    audiorelay \
    gamemode \
    discord \
    steam \
    razer-cli \
    openrgb

set work_packages \
    slack-desktop \
    delve \
    flutter \
    lazysql \
    google-chrome \
    visual-studio-code-bin \
    gitlab-ci-local \
    logiops \
    blueman \
    dotnet-sdk \
    rofi-rbw

if mt_is_work
    yay --needed -S $work_packages --noconfirm

    if not systemctl is-enabled --quiet logid.service
        sudo systemctl enable --now logid.service
    end
else if mt_is_personal
    yay --needed -S $personal_packages --noconfirm
end

yay --needed -S \
    $core_packages \
    $gui_packages \
    $hyprland_packages \
    $font_packages \
    $dev_packages \
    --noconfirm

print_info "Configuring and install misc tools"

if ! type -q rustc
    curl https://sh.rustup.rs -sSf | sh -s -- -y
end

cargo install --locked cargo-nextest
cargo install --locked cargo-llvm-cov
cargo install --locked gpu-usage-waybar
cargo install --locked tree-sitter-cli
cargo install --locked zoxide

print_success Done
