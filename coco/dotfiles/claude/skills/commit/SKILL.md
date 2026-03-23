---
name: commit
description: Create a git commit using conventional commit format. Use when the user asks to create a commit, commit changes, or make a git commit.
user-invocable: true
---

# Create Git Commit

Create a git commit using conventional commit format, with an inline review step.

1. Run `git diff --staged` to see staged changes
2. Assess whether the staged changes are cohesive. If they appear to span unrelated concerns
   (e.g. a bug fix mixed with a refactor, or changes to unrelated features), warn the user.
   Use AskUserQuestion with the list of changed files and a brief explanation of why they seem
   unrelated, offering: `["Continue anyway", "Unstage some files", "Cancel"]`
   - **"Unstage some files"**: ask which files to unstage, run `git restore --staged <files>`, then re-check
   - **"Cancel"**: stop
3. Check whether the user has forgotten related changes unstaged and stage with `git add` if needed
4. Draft a conventional commit message:
   - Use prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `style:`, `test:`
   - Keep the subject line concise (≤50 chars preferred)
   - Add a blank line and body with more detail if needed
   - Write the body using GitHub-flavoured markdown: `- ` bullet lists, `**bold**`, backticks for code
5. Run `pre-commit run`. If the repo has no git hooks, ignore the error and continue.
6. Commit the changes

**IMPORTANT**:
- Never include Claude, AI, or co-authorship mentions
- Follow the repository's existing commit style
- Do NOT run `git push` unless explicitly requested
