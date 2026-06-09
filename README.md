# Linux dotfiles for Arch-based distros

I have 2 starter scripts, `apply` and `install-arch`.

## apply

This script runs my install scripts for my system. This includes everything from installing packages to adding users to groups.

These scripts are made to be run multiple times without issue.

## install-arch

An install script that installs Arch Linux from a live boot medium onto your machine.

> This script is very specific for my setup. It was made as a learning exercise so there's probably some issues. Use at your own risk.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/rahmerh/dotfiles/main/install-arch)"
```

This script installs Arch Linux on a single disk. It creates EFI and root partitions (no swap), installs Arch on the disk, and configures the base system. Run the `apply` script afterwards to finish the installation.

Features I want to add in the future:

- Wi-Fi connection for laptops
- Disk encryption
- Multiple drive setup
- Maybe btrfs setup?
