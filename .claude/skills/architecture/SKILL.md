---
name: architecture
description: Shows NixOS dotfiles repository architecture and structure. Use when asked about repo layout, key components, desktop environment, dotfile management, or how the repository is organized.
user-invocable: true
---

# Repository Architecture

A flake for the "coco" machine (ThinkPad X1 9th gen), organised with the
dendritic pattern: every `.nix` file under `modules/` is a flake-parts module,
loaded automatically by import-tree. `flake.nix` holds only inputs and
`mkFlake { inherit inputs; } (import-tree ./modules)`.

## Features

A feature is a file (or directory) that publishes modules under one name, for
each layer it touches:

- `flake.modules.nixos.<name>`: NixOS side (services, system packages, PAM)
- `flake.modules.homeManager.<name>`: home-manager side (user packages, dotfiles)
- `perSystem.packages.<name>`: packages it builds or wraps (`nix run .#<name>`)

For example `modules/terminal/tmux/tmux.nix` installs tmux system-wide, links
`tmux.conf` and adds the tmux shell aliases. The same name may be defined in
several files (`flake.modules` merges them), e.g. `theme` spans
`modules/desktop/theme/theme.nix` and `toolkits.nix`.

Feature modules take `inputs` and `self` from the flake-parts scope; there are
no specialArgs.

## Layout

- `modules/flake/`: systems, dev shell and pre-commit checks, `flake.modules` support
- `modules/hosts/coco/`: the nixosConfiguration (`default.nix`), host-only
  settings and the lists of nixos and homeManager features it uses
  (`configuration.nix`), and the generated `_hardware-configuration.nix`
- `modules/system/`: nix settings, base packages, locale, network, security
  (ssh agent, KeePassXC), input (xkb + XCompose), fonts, audio, oom, ...
- `modules/desktop/`: niri, waybar, swaylock, mako, theme (tinty/darkman, GTK/Qt), files (Dolphin)
- `modules/shell/`, `modules/terminal/`, `modules/editor/`, `modules/dev/`, `modules/apps/`
- `modules/home/dotfiles.nix`: the `link-dotfile` and `dotfile-path` helpers
- `modules/users/cgeorgii.nix`: the user account and home-manager basics

import-tree only loads `*.nix` files and skips any path containing `/_`, so
plain NixOS modules or `callPackage` files that aren't flake-parts modules get
a `_` prefix (`_hardware-configuration.nix`, `_xcompose.nix`, `whispering/_package.nix`).

## Dotfile Management

Hot-reloaded dotfiles live next to the feature that links them (niri's
`config.kdl` beside `niri.nix`, `nvim/` beside `neovim.nix`). Features link
them with `link-dotfile ./config.kdl`, an out-of-store symlink into the
`~/dots` checkout, so edits apply without a rebuild. `dotfile-path ./file`
gives the checkout path as a string, for scripts and settings. Both fail
evaluation if the file is missing or not tracked by git.

## Wrapped Programs

Programs whose config is fully declared in Nix are wrapped with
nix-wrapper-modules and exposed as packages: kitty, swaylock and mako. Their
config lives in the store, so changing it needs a rebuild. Hot-reloaded or
tinty-rendered configs (niri, waybar, nvim, fuzzel, tmux, zellij, claude,
lazygit) stay on home-manager links. Starship stays on home-manager because
`starship init` would bypass the wrapper's `STARSHIP_CONFIG`.

## Desktop Environment

- Niri (Wayland compositor), Waybar (status bar), Fuzzel (launcher)
- Kitty (terminal), tmux / Zellij (multiplexers)
- tinty + darkman for runtime light/dark and colour schemes

## Git Hooks

- Pre-commit hooks via github:cachix/git-hooks.nix: nixfmt, deadnix and tagref
- `nix develop` installs them; the dev shell also has nil, git-bug and tagref

## Roadmap and Cross-references

- Open work is in `ROADMAP.md` (conventions, inbox, items), finished and
  dropped work in `COMPLETED.md`, and every ID with its area in `INDEX.md`.
- Comments and docs link with tagref sigils: a tag marks a roadmap item or a
  shared concept, a ref cites it, and file/dir sigils pin hardcoded checkout
  paths. `tagref check` runs as a pre-commit hook.
