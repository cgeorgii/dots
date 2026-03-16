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
3. Stage files with `git add` if needed
4. Draft a conventional commit message:
   - Use prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `style:`, `test:`
   - Keep the subject line concise (≤50 chars preferred)
   - Add a blank line and body with more detail if needed
   - Write the body using GitHub-flavoured markdown: `- ` bullet lists, `**bold**`, backticks for code
5. Write the draft to `.git/COMMIT_EDITMSG` using the Write tool (not Bash)
6. Use AskUserQuestion with `["Commit", "Abort"]`
   - **"Commit"**: run `git commit -F .git/COMMIT_EDITMSG --cleanup=strip`
   - **"Abort"**: inform the user the commit was cancelled

**IMPORTANT**:
- Never include Claude, AI, or co-authorship mentions
- Follow the repository's existing commit style
- Do NOT run `git push` unless explicitly requested
