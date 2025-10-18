Create a git commit using conventional commit format.

1. Run `git status` and `git diff --staged` to see staged changes
2. Run `git log -5 --oneline` to check commit history style
3. Analyze the changes and create a conventional commit message:
   - Use prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `style:`, `test:`
   - Keep the summary line concise (≤50 chars preferred)
   - Add details in body if needed
4. Stage files with `git add` if needed
5. Commit with a HEREDOC to preserve formatting:

```
git commit -m "$(cat <<'EOF'
<type>: <concise summary>

<optional body with more details>
EOF
)"
```

**IMPORTANT**:
- Never include Claude, AI, or co-authorship mentions
- Follow the repository's existing commit style
- Do NOT run `git push` unless explicitly requested
