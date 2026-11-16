# Completed

Finished and dropped roadmap items, newest first. Each keeps its ID, with its
final status (`done` or `dropped: <reason>`). Conventions are in
[ROADMAP.md](ROADMAP.md); every ID is registered in [INDEX.md](INDEX.md).

## Items

### 1.6 — Fetch GitHub over HTTPS with a read-only token [tag:1.6-github-readonly-fetch]

**Kind:** feature
**Status:** done
**Depends on:** none

Every fetch from a `git@github.com:` remote needed an SSH signature, and
lazygit's background fetches made KeePassXC's confirmation constant enough to
click through on reflex. git-credential-manager also sat in the global
config, ready to hand a full-scope GitHub token to any process.

- **Reads** from github.com go over HTTPS: `insteadOf` rewrites
  `git@github.com:` and `ssh://git@github.com/` remotes. They authenticate
  with a fine-grained PAT, `Contents: read` on my own repositories only,
  stored as the sops secret `github-ro-token`, owned by me, mode `0400`.
- **Writes** go back to `git@github.com:` through `pushInsteadOf`, with the
  identity mapping, since git applies it to the configured URL, so they still
  sign with the key.
- **Credentials:** `git-ro-credential TOKEN_FILE USERNAME` is the only helper
  for `https://github.com`. It answers `get` from the file, ignores `store`
  and `erase`, and always ends with `quit=1`, so a missing or insufficient
  token fails instead of opening an `SSH_ASKPASS` username dialog.
  `credential.interactive=false` doesn't stop that dialog in git 2.56. Its
  arguments make it reusable for [ref:1.3-agent-secrets] and a work GitLab
  token.
- git-credential-manager is gone. It held no credentials and nothing else
  used it. `~/.gitconfig` doesn't exist, so `gh` adds no helper.
- Private repositories of other owners are not covered; none are in use.
- jj shells out to git, so it follows the same rewrites.

**Done when:** remotes in `git@github.com:` form show HTTPS for fetch and
SSH for push in `git remote -v`; fetching a private repository succeeds
without a KeePassXC prompt or notification, and lazygit left open causes
none; a push still prompts; `git credential fill` for github.com returns the
read-only token and nothing else does.

### 2.1 — Try noctalia as the desktop shell [tag:2.1-noctalia-shell]

**Kind:** proposal
**Status:** done
**Depends on:** none

Noctalia v5, from upstream's flake, is now the only desktop shell around
niri. It replaced waybar and niri-taskbar, mako, fuzzel, swaylock and swaybg.

- **Trial:** it first ran as a NixOS specialisation beside the old setup,
  chosen by a `desktop.shell` option. Once it had proven itself, the option,
  the specialisation and the old shell's features were removed.
- **Config:** a hot-reloaded `config.toml`, plus `settings.toml`, which the
  Settings window writes through a link into the checkout. Its launcher, lock
  and window-rule binds go into the `shell.kdl` include for niri.
- **Colours:** tinty stays the source of truth. `tinty-render.sh` writes the
  active base16 palette as a noctalia custom palette, plus the mode, wallpaper
  and the theme button's tooltip.
- **Locking:** a `session_locked` hook also locks KeePassXC.

**Done when:** the specialisation boots into niri with noctalia replacing the
bar, notifications, launcher, lock screen and wallpaper; locking still locks
KeePassXC; switching to and from the specialisation works without a rebuild;
and noctalia follows tinty's light/dark and scheme changes.
