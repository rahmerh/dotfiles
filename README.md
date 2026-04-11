# Linux dotfiles for arch-based distros

## Setup

I've included an install script to easily get set up. If you want to live on the edge and directly install execute the following:

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rahmerh/dotfiles/main/auto-setup)"
```

## Arch install

I have an auto install script that installs linux from a live boot medium on to your machine.

> This script is very specific for my setup. It was made as a learning exercise so there's probably some issues. Use at your own risk.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rahmerh/dotfiles/main/install-arch)"
```

This script installs arch linux on a single disk. It creates an EFI and root partition (no swap) and installs arch on the disk.

Features I want to add:

- Wifi connection for laptops
- Disk encryption
- Multiple drive setup
- Maybe btrfs setup?
