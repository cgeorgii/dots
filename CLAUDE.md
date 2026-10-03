# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

**This repository defines the currently running NixOS system configuration.**

## Critical Rules

- **Never mention Claude or AI in commits**: When creating commits, never include references to Claude, AI assistants, or co-authorship mentions
- **Never run sudo commands directly**: Always ask the user to run them in a separate terminal
- **All changes via declarative Nix config**: Never modify system files directly; use NixOS/Home-Manager configuration files
- **Don't edit systemd services directly**: Use the appropriate Nix modules instead
- **Refactor narration** - when necessary - should be done in the chat, not in comments in the produced code.

## Layout

Dendritic flake-parts layout: every `.nix` file under `modules/` is loaded by import-tree, and features publish `flake.modules.nixos.<name>` / `flake.modules.homeManager.<name>` (and `perSystem.packages`) that `modules/hosts/coco/configuration.nix` composes. Files that are plain modules rather than flake-parts modules get a `_` prefix. See the `architecture` skill.

## Dotfile Management

Hot-reloaded dotfiles live next to the feature that uses them and are linked with `link-dotfile ./file` (an out-of-store symlink into `~/dots`), so edits apply without rebuilds. Use `dotfile-path ./file` when a script or setting needs the path as a string.

**When adding new configuration files**: put them beside the feature module and link them with `link-dotfile` rather than copying files. Configs fully declared in Nix can instead be wrapped as a package with nix-wrapper-modules (see kitty, swaylock, mako).

**Important**: When creating new files for Nix flakes, ensure they are tracked by git before testing with nix commands. Use `git add -N path/to/file` to track without staging.
