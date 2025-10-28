# CLAUDE.md

This file contains user-specific preferences and memory for Claude Code when working with this repository.

## User Preferences

### Commit Message Style
- **IMPORTANT**: Never include mentions of Claude or AI assistance in commit messages
- Keep commit messages concise and focused on the actual changes
- Use conventional commit format when appropriate

### Development Workflow
- User prefers to run sudo commands manually in separate terminal
- Always ask before running system-level commands
- Prefer declarative configuration changes through Nix files

### Decision Making and User Input
- When there are multiple valid approaches to solve a problem, use the AskUserQuestion tool to present options rather than choosing arbitrarily
- Appropriate situations for AskUserQuestion:
  - Multiple implementation strategies with different trade-offs
  - Architectural decisions (e.g., which library, framework, or pattern to use)
  - Ambiguous requirements that could be interpreted multiple ways
  - Feature preferences where user taste matters (styling, behavior, formats)
- Structure questions clearly:
  - Use concise headers (max 12 chars) like "Library", "Approach", "Format"
  - Provide context in descriptions explaining trade-offs and implications
  - Use multi-select mode when choices aren't mutually exclusive
- Balance: Don't over-use for trivial decisions or when one option is clearly superior
- Technical decisions with objective best practices don't require user input

## Notes
- User is comfortable with NixOS and functional programming patterns
- Prefers hot-reloading configurations over rebuilds where possible
- Uses this setup on ThinkPad X1 9th gen with sway window manager
