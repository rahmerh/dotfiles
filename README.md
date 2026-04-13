# Linux dotfiles for arch-based distros

I have 2 starter scripts, `apply` and `install-arch`.

## apply

This script runs my install scripts for my system. This includes everything from installing packages to adding users to groups.

These scripts are made to be run multiple times without issue.

## install-arch

An install script that installs linux arch from a live boot medium on to your machine.

> This script is very specific for my setup. It was made as a learning exercise so there's probably some issues. Use at your own risk.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rahmerh/dotfiles/main/install-arch)"
```

This script installs arch linux on a single disk. It creates an EFI and root partition (no swap) and installs arch on the disk. It also configures everything after so the only thing to do is to run the `apply` script to finish the installation.

Features I want to add in the future:

- Wifi connection for laptops
- Disk encryption
- Multiple drive setup
- Maybe btrfs setup?
