# Completed

Finished and dropped roadmap items, newest first. Each keeps its ID, with its
final status (`done` or `dropped: <reason>`). Conventions are in
[ROADMAP.md](ROADMAP.md); every ID is registered in [INDEX.md](INDEX.md).

## Items

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
