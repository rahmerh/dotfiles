# Repository Guidelines

## Project Structure & Module Organization

This repository manages an Arch-based workstation through dotfiles and install scripts. `home/` is a GNU Stow package: its hidden paths mirror the target home directory, for example `home/.config/nvim/` and `home/.bashrc.d/`. `system/` contains files copied into system locations, grouped by feature such as `system/sddm/` and `system/system-backup/`.

Provisioning lives in `install-scripts/`. Numbered directories and scripts define execution order (`00-core/01-install-packages`, `30-theming/04-firefox`). Shared Bash helpers are in `install-scripts/lib/`; wallpapers and icons are in `install-scripts/assets/`. The root entry points are `apply` for post-install configuration and `install-arch` for a live-medium Arch installation.

## Build, Test, and Development Commands

- `./apply`: validates and runs every executable installer in version order, then stows `home/`. Expect package installs, `sudo`, and machine-specific prompts.
- `./install-arch`: installs Arch from live media. It partitions a selected disk; read the script before running it.
- `stow --target="$HOME" home`: apply only the home dotfile package when system provisioning is not needed.
- `bash -n apply install-arch install-scripts/00-core/01-install-packages`: syntax-check changed Bash entry points and scripts.
- `shellcheck --exclude=SC1091 apply install-arch install-scripts/00-core/01-install-packages`: lint changed Bash entry points and scripts; dynamic helper imports cannot be resolved statically.

There is no compiled build step in this repository.

## Package Management Preferences

Avoid npm for global tooling whenever possible; this is an important repository preference. Prefer Arch repository or AUR packages installed through the idempotent package arrays in `install-scripts/00-core/01-install-packages`. Do not add npm-based global installs when a practical pacman or AUR package exists. If npm is genuinely unavoidable, make that tradeoff explicit.

## Coding Style & Naming Conventions

Keep Bash scripts executable and start them with a Bash shebang. `apply` rejects install scripts that do not match `NN-name`, are non-executable, or are not Bash scripts. Use four-space indentation in Bash and Lua, keep helper logic in `install-scripts/lib/`, and follow nearby config syntax for KDL, JSONC, TOML, CSS, and systemd units. Preserve directory mirroring when adding dotfiles or system files.

## Testing Guidelines

The repository does not currently define an automated test suite or coverage target. For script changes, run `bash -n` and `shellcheck` on touched Bash files and review whether the script is idempotent: `apply` is intended to be safe to run repeatedly. Do not add migration, backfill, or legacy compatibility branches to provisioning scripts unless explicitly requested; prefer one current canonical path or behavior. For configuration changes, verify the affected tool locally, such as Neovim, Waybar, Niri, or the relevant systemd unit.

## Commit & Pull Request Guidelines

Recent history uses short, free-form summaries such as `Sddm theme` and `Copy system files...`; keep commit subjects concise and focused on one behavior. Pull requests should describe the target machine context, list changed provisioning or config paths, call out privileged or destructive steps, and include screenshots for visible theme, SDDM, Waybar, or window-manager changes.

## Security & Configuration Tips

Do not commit credentials, machine secrets, or private SSH material. Treat `.prefs` as local preferences that affect provisioning decisions.
