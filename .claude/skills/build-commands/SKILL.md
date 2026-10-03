---
name: build-commands
description: Reference for NixOS build, test, and flake commands. Use when asked about rebuilding, checking config, formatting, or flake operations.
user-invocable: true
---

# Build/Test Commands

## NixOS Operations

- **Rebuild system**: `sudo nixos-rebuild switch --flake ~/dots#coco`
  (plain `sudo nixos-rebuild switch` also works: it follows the
  `/etc/nixos/flake.nix` symlink to `~/dots`)
- **Build without switching**: `nix build .#nixosConfigurations.coco.config.system.build.toplevel`
- **Compare with the running system**: `nix store diff-closures /run/current-system ./result`
- **Build the home-manager generation**: `nix build .#nixosConfigurations.coco.config.home-manager.users.cgeorgii.home.activationPackage`

## Packages

- **Build or run a flake package**: `nix build .#kitty`, `nix run .#workmux`
  (packages: firefox, kitty, mako, swaylock, whispering, workmux)

## Flake Operations

- **Check flake**: `nix flake check`
- **Show outputs**: `nix flake show`
- **Update flake inputs**: `nix flake update`
- **Setup dev environment**: `nix develop` (enables pre-commit hooks and development tools)

## Formatting

- **Format Nix files**: `nixfmt file.nix`

## Important Notes

- New files must be tracked by git before nix sees them: `git add -N path`
- User prefers to run sudo commands manually in a separate terminal
- Always ask before running system-level commands
- All configuration changes should be done declaratively through Nix files
