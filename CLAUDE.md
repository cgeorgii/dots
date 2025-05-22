# CLAUDE.md - NixOS Dotfiles Repository Guide

## Assistant Guidelines
- Never run sudo commands directly; always ask the user to run them
- User will run sudo commands in a separate terminal and paste the results

## Build/Test Commands
- NixOS rebuild: `sudo nixos-rebuild switch`
- Link dotfiles: `sudo ln -s /home/cgeorgii/dots/* /etc/nixos`
- Check config: `nixos-rebuild dry-build`
- Format Nix files: `nixpkgs-fmt file.nix`
- Setup git hooks: `nix develop`

## Git Hooks
- Pre-commit hooks are enabled via github:cachix/git-hooks.nix
- Run `nix develop` to activate hooks in your local environment
- Enabled hooks:
  - nixpkgs-fmt: Auto-formats Nix files
  - statix: Lints Nix code for anti-patterns
  - deadnix: Finds unused variables in Nix files
  - repomix-update: Updates repomix data before commits

## NixOS/Home-Manager Style Guidelines
- Use 2-space indentation in all files
- Format Nix files with `nixpkgs-fmt`
- Follow functional programming patterns
- Group related settings in modules
- Use descriptive names for options
- Document non-obvious settings with comments

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

## Repomix Integration
- Always check repomix-output.xml when making repository changes
- Consider the metadata in repomix-output.xml for compatibility decisions
