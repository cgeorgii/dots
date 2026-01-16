---
name: architecture
description: Shows NixOS dotfiles repository architecture and structure. Use when asked about repo layout, key components, desktop environment, dotfile management, or how the repository is organized.
user-invocable: true
---

# Repository Architecture

This is a NixOS dotfiles repository with flake-based configuration that manages:
- NixOS system configuration for "coco" machine (ThinkPad X1 9th gen)
- Home-Manager user configurations with dotfile symlinks
- Automated git repository synchronization via systemd services
- Development environment with pre-commit hooks

## Key Components

- `flake.nix`: Main flake with nixos-hardware, home-manager, and custom app integration
- `common.nix`: System-wide packages and configuration shared across machines
- `home/cgeorgii.nix`: User-specific configuration with dotfile symlinks and Niri/Waybar setup
- `nix/git-repos.nix`: Custom NixOS module for automatic git repository management
- `dotfiles/`: Configuration files symlinked via home-manager

## Desktop Environment

- Niri (Wayland compositor)
- Waybar (status bar)
- Fuzzel (application launcher)
- Kitty (terminal emulator)
- Zellij (terminal multiplexer)

## Dotfile Management Strategy

Uses `config.lib.file.mkOutOfStoreSymlink` to create symlinks instead of copying files, enabling hot-reloading without rebuilds. All dotfiles live in `dotfiles/` and are symlinked to appropriate locations.

Configuration files for the user's home directory are symlinked in `home/cgeorgii.nix`. When adding new configuration files, follow this pattern by placing them in `dotfiles/` and creating symlinks through home-manager rather than copying files.

## Git Hooks

- Pre-commit hooks are enabled via github:cachix/git-hooks.nix
- Run `nix develop` to activate hooks in your local environment
- Enabled hooks:
  - nixfmt: Auto-formats Nix files
  - deadnix: Finds unused variables in Nix files
- Development shell includes: nil (Nix LSP), git-bug (issue tracker)

## Automated Repository Management

- `nix/git-repos.nix` provides systemd service for automatic git repository syncing
- Configured repositories are cloned and kept up-to-date automatically
- Service runs on boot and every 30 minutes
- Skips updates if repositories have uncommitted changes
