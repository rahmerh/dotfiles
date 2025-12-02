#!/bin/bash
if ! command -v pacman &>/dev/null; then
    source /etc/os-release
    echo "These dotfiles are written for Arch-based systems; you're on ${PRETTY_NAME:-$ID}"
    exit 1
fi

printf "This script will install and configure fish to be your default shell.\n"
printf "This script only needs to be run once, after that run apply.fish to apply your changes to your system.\n"

# Configuring/installing shell
printf "Installing fish.\n"

if ! command -v fish &> /dev/null; then
    echo "Installing fish and gum"
    sudo pacman -Sy --noconfirm fish
else
    echo "Fish already installed"
fi

sudo pacman -Sy --noconfirm gum

if [ "$SHELL" != "/usr/bin/fish" ]; then
    chsh -s /usr/bin/fish
else 
    printf "Shell already fish.\n"
fi

if [ -d "$HOME/dotfiles" ]; then
    gum style --foreground 202 --border normal --padding "1 2" --margin "1 0" "⚠️  ~/dotfiles already exists — skipping clone"
else
    gum style --foreground 34 --border normal --padding "1 2" --margin "1 0" "📦 Cloning dotfiles..."
    git clone https://github.com/Rahmerh/dotfiles.git ~/dotfiles
fi

printf "Run the following commands once to finish setup: \n git config user.name \"Your name\" \n git config user.email \"Your email\""
printf "Dotfiles cloned into: \"~/dotfiles\", please run the 'apply.fish' script to apply all changes from this repo."
