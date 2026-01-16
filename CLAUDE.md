# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

**This repository defines the currently running NixOS system configuration.**

## Critical Rules

- **Never mention Claude or AI in commits**: When creating commits, never include references to Claude, AI assistants, or co-authorship mentions
- **Never run sudo commands directly**: Always ask the user to run them in a separate terminal
- **All changes via declarative Nix config**: Never modify system files directly; use NixOS/Home-Manager configuration files
- **Don't edit systemd services directly**: Use the appropriate Nix modules instead

## Dotfile Management

Uses `config.lib.file.mkOutOfStoreSymlink` to create symlinks instead of copying files, enabling hot-reloading without rebuilds. All dotfiles live in `dotfiles/` and are symlinked to appropriate locations.

**When adding new configuration files**: Place them in `dotfiles/` and create symlinks through home-manager in `home/cgeorgii.nix` rather than copying files.

**Important**: When creating new files for Nix flakes, ensure they are tracked by git before testing with nix commands. Use `git add -N path/to/file` to track without staging.
