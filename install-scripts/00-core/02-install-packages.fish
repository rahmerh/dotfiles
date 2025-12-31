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
    bc

# GUI/system tools
set gui_packages \
    firefox \
    firewalld \
    lazygit \
    pulsemixer \
    borg \
    rofi \
    docker \
    docker-compose \
    nvidia-container-toolkit \
    nwg-displays \
    keychain \
    brightnessctl

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
    xdg-desktop-portal-hyprland

# Fonts
set font_packages \
    ttf-jetbrains-mono-nerd

# Dev tools
set dev_packages \
    dotnet-sdk \
    npm \
    qt5-tools

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
    go \
    delve \
    flutter \
    lazysql \
    google-chrome \
    visual-studio-code-bin \
    gitlab-ci-local \
    logiops \
    blueman

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

if ! type -q zoxide
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
end

if ! type -q mcfly
    sudo bash -c 'curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly'
end

if ! type -q rustc
    curl https://sh.rustup.rs -sSf | sh -s -- -y
end

cargo install cargo-nextest
cargo install cargo-llvm-cov
cargo install gpu-usage-waybar

print_success Done
