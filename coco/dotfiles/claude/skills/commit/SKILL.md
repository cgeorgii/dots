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
5. Use the AskUserQuestion tool to present the draft inline. Set the question text to the full
   commit message so the user can read it, and offer these options:
   `["Accept message above", "Edit (write to .git/COMMIT_EDITMSG)", "Cancel"]`
6. Based on the answer:
   - **"Accept message above"**: commit directly using the drafted message via heredoc (`git commit -m "$(cat <<'EOF' ... EOF)"`)
   - **"Edit"**: write the draft to `.git/COMMIT_EDITMSG`, tell the user to run `ge` (or `g e`) to edit it, then use AskUserQuestion again with `["Commit", "Abort"]`; if "Commit" run `git commit -F .git/COMMIT_EDITMSG --cleanup=strip`
   - **"Cancel"**: inform the user the commit was cancelled

**IMPORTANT**:
- Never include Claude, AI, or co-authorship mentions
- Follow the repository's existing commit style
- Do NOT run `git push` unless explicitly requested
