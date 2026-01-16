# CLAUDE.md

User-specific preferences and behavioral guidelines for Claude Code across all projects.

## Behavioral Guidelines

### Commit Messages
- **Never mention Claude or AI assistance in commits**
- Keep messages concise and focused on actual changes
- Use conventional commit format when appropriate

### Development Workflow
- User prefers to run sudo commands manually in separate terminal
- Always ask before running system-level commands
- Prefer declarative configuration changes through Nix files

### Decision Making
- When multiple valid approaches exist with different trade-offs, use AskUserQuestion to present options
- Ask for user input on: architectural decisions, ambiguous requirements, user preference matters (styling, behavior)
- Don't over-use for trivial decisions or when one option is clearly superior

## User Context
- Comfortable with NixOS and functional programming patterns
- Prefers hot-reloading configurations over rebuilds where possible
