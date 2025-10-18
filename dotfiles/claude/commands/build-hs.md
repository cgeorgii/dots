Start a ghcid session to monitor the build.

**Before starting**: Verify which command is actually allowed in `.claude/settings.local.json` for ghcid and ensure you use it to avoid prompting for permission.

First, check `package.yaml` to identify the components:
- `library:` section → use the package name (e.g., `dota-sage`)
- `executables:` section → use the executable name with `-exe` suffix (e.g., `dota-sage-exe`)
- `tests:` section → use the test name with `-test` suffix (e.g., `dota-sage-test`)

Then run ghcid with all components using the Bash tool with `run_in_background: true`:

```
nix develop -c ghcid -c 'cabal repl --enable-multi-repl <library-name> <executable-name> <test-name>' --outputfile=build.log --clear > /dev/null 2>&1
```

For this project:
```
nix develop -c ghcid -c 'cabal repl --enable-multi-repl dota-sage dota-sage-exe dota-sage-test' --outputfile=build.log --clear > /dev/null 2>&1
```

**IMPORTANT**: Use `run_in_background: true` parameter in the Bash tool (without `&` at the end) so ghcid appears in Claude Code's background processes UI.

To keep context usage reasonable, the output is redirected to /dev/null and only the file build.log is used to monitor the build status, ideally reading only the first few lines and then more if needed using the Read tool.

**Monitoring build status**:
- Check for errors: Use Read tool with `file_path: "build.log"` and `limit: 20`
- Check if ghcid is running: View background processes in Claude Code UI, or `ps aux | grep ghcid`
- Kill ghcid: Use KillShell tool with the shell ID, or `pkill ghcid`

**When to restart ghcid**:
- After adding/removing/renaming Haskell files (run `nix develop -c hpack` first to regenerate cabal)
- After changing `package.yaml` (run `nix develop -c hpack` first)
- If ghcid appears stuck or unresponsive

**Important**: If you add a new component (library, executable, or test suite) to `package.yaml`, you must also remind me to update the permission in `.claude/settings.local.json` to include the new component name in the ghcid command.

**Note**: Avoid building the project directly with cabal or stack. Let ghcid monitor compilation continuously.
