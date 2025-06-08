# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a NixOS dotfiles repository with flake-based configuration that manages:
- NixOS system configuration for "coco" machine (ThinkPad X1 9th gen)
- Home-Manager user configurations with dotfile symlinks
- Custom applications (repomix-to-clipboard) as flake modules
- Automated git repository synchronization via systemd services
- Development environment with pre-commit hooks

### Key Components
- `flake.nix`: Main flake with nixos-hardware, home-manager, and custom app integration
- `common.nix`: System-wide packages and configuration shared across machines
- `home/cgeorgii.nix`: User-specific configuration with dotfile symlinks and sway/i3status-rust setup
- `apps/repomix-to-clipboard/`: Custom flake module for AI-friendly repository packaging
- `nix/git-repos.nix`: Custom NixOS module for automatic git repository management
- `dotfiles/`: Configuration files symlinked via home-manager

### Dotfile Management Strategy
Uses `config.lib.file.mkOutOfStoreSymlink` to create symlinks instead of copying files, enabling hot-reloading without rebuilds. All dotfiles live in `dotfiles/` and are symlinked to appropriate locations.

## Assistant Guidelines
- Never run sudo commands directly; always ask the user to run them
- User will run sudo commands in a separate terminal and paste the results
- Never modify system files directly; always make changes through NixOS/Home-Manager configuration files
- All configuration changes should be done declaratively through Nix configuration files
- Don't edit systemd service files directly; use the appropriate Nix modules instead

## Build/Test Commands
- NixOS rebuild: `sudo nixos-rebuild switch`
- Link dotfiles: `sudo ln -s /home/cgeorgii/dots/* /etc/nixos`
- Check config: `nixos-rebuild dry-build`
- Format Nix files: `nixpkgs-fmt file.nix`
- Setup development environment: `nix develop` (enables pre-commit hooks and development tools)
- Build specific configurations: `nix build .#nixosConfigurations.coco.config.system.build.toplevel`
- Check flake: `nix flake check`
- Update flake inputs: `nix flake update`

## Git Hooks
- Pre-commit hooks are enabled via github:cachix/git-hooks.nix
- Run `nix develop` to activate hooks in your local environment
- Enabled hooks:
  - nixpkgs-fmt: Auto-formats Nix files
  - deadnix: Finds unused variables in Nix files
- Development shell includes: nil (Nix LSP), git-bug (issue tracker), repomix-to-clipboard

## NixOS/Home-Manager Style Guidelines
- Use 2-space indentation in all files
- Format Nix files with `nixpkgs-fmt`
- Follow functional programming patterns
- Group related settings in modules
- Use descriptive names for options
- Document non-obvious settings with comments
- When creating new files for Nix flakes, ensure they are tracked by git before testing with nix commands
  - Untracked files can cause errors like "path '/nix/store/hash-source/path/to/file' does not exist"
  - Solution: Track files without staging using `git add --intent-to-add path/to/file` or `git add -N path/to/file`

## Neovim Style Guidelines
- Use Lua for all configuration
- 2-space indentation, no tabs
- Leader key is `;`
- Format with proper whitespace and bracing style
- Wrap related plugin configs in feature-based groups
- Prefer native LSP functions over plugin equivalents

## Git Workflow
- Create focused, atomic commits
- Use `hub` as git wrapper
- Use `lazygit` for interactive Git operations
- Prefer rebase over merge for linear history
- Do not include co-authored by Claude information in commits
- Git config location: `~/.config/git/config`
- Use libsecret credential helper for HTTPS credentials
- For credential storage:
  - Initialize pass: `pass init YOUR_GPG_KEY_ID`
  - Uses pass-secret-service to bridge between libsecret and pass
  - Credentials stored securely with GPG encryption

## Custom Applications

### repomix-to-clipboard
- Located in `apps/repomix-to-clipboard/` as a flake module
- Packages repositories for AI analysis and copies to clipboard
- Available as `rc` alias in shell
- Configuration in `repomix.config.json`

## Automated Repository Management
- `nix/git-repos.nix` provides systemd service for automatic git repository syncing
- Configured repositories are cloned and kept up-to-date automatically
- Service runs on boot and every 30 minutes
- Skips updates if repositories have uncommitted changes

## Repomix Integration
- Always check repomix-output.xml when making repository changes
- Consider the metadata in repomix-output.xml for compatibility decisions

## Git-Bug Issue Tracker
- Use `git bug` to manage issues directly in the repository
- List issues: `git bug ls`
- Create a new issue: `git bug new`
- Show issue details: `git bug show <id>`
- Add a comment: `git bug comment <id>`
- Edit an issue: `git bug edit <id>`
- Change issue status: `git bug status <id> <new-status>`
- Pull/push issues: `git bug pull` and `git bug push`
