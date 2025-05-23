# CLAUDE.md - NixOS Dotfiles Repository Guide

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
