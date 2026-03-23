---
name: ghcid
description: Monitor a running ghcid session. Use when ghcid is already running in the background and you need to check build status, wait for a clean build, or interpret build.log output.
user-invocable: true
---

# Monitoring a Running ghcid Session

ghcid is running in the background and writing to `build.log`. Read that file repeatedly until the build is clean.

**Check build status**:
- Use Read tool with `file_path: "build.log"` and `limit: 20`
- Read more lines only if the initial output suggests errors further down

**What a clean build looks like**: `All good (N modules)` with no error lines.

**What to do**:
1. Read `build.log`
2. If errors are present, fix them and re-read — no need to sleep, ghcid recompiles immediately on file save
3. If clean, you're done

**Incremental compilation**:
- After the initial build, recompilation is essentially instant
- **Do not add `sleep` delays** between edits and checking `build.log`
- If ghcid is still compiling, `build.log` will show the in-progress status

## Spurious Warning on First Cycle

The very first build cycle may show:
```
<interactive>:1:1: warning: [GHC-85401] [-Wmissing-export-lists]
    The export item 'module Ghci1' is missing an export list
```

This is a false negative from ghcid's internal repl setup — **not a real problem**. It disappears on the next recompilation. Do not act on it; if uncertain, touch any source file to trigger a cycle and confirm the build is clean.

## Module Changes During a Session

- **New module added**: ghcid picks it up automatically on the next recompilation cycle.
- **Module deleted or renamed**: ghcid dies and will **not** self-recover, even after running `hpack --force`. Kill ghcid and start a new session (see `/build-hs`).

## Other Checks

- **Is ghcid still running?** View background processes in the Claude Code UI, or `ps aux | grep ghcid`
- **Kill ghcid**: Use the KillShell tool with the shell ID, or `pkill ghcid`
