# Roadmap

Open work for this configuration. Every ID is registered in [INDEX.md](INDEX.md);
finished and dropped items are in [COMPLETED.md](COMPLETED.md).

## Conventions

**Every item has an ID `<area>.<n>`**, where `<area>` is one of the areas in
[INDEX.md](INDEX.md) and `<n>` is the next free number in that area. The index
is the record of every ID: adding the index row is what creates an ID, so add
it before the item. IDs are identities, not an ordering: they never change and
are never reused, even when an item is dropped. Ordering comes from
`Depends on:` lines.

**Every item heading ends with a tagref tag** named `<id>-<slug>`, the slug
two to four kebab-case words, as on the items below. Cite an item anywhere in the
repository, in Nix comments, scripts, docs or other items, only through a
`ref:` sigil to that tag, never as a bare "2.1"; the index rows do the same.
`tagref check` (a pre-commit hook) rejects refs to missing tags and duplicate
tags, and `tagref list-refs | grep <id>` finds everything that touches an item.

**Fields** sit directly under the heading, one per line, in this order:

- `**Kind:**` `feature` | `bug` | `proposal` | `chore`
- `**Status:**` `open` | `in-progress (<branch or worktree>)` |
  `blocked: <reason>` | `done` | `dropped: <reason>`
- `**Depends on:**` comma-separated refs to other items, or `none`

The body says what and why, and ends with `**Done when:**`, an observable
acceptance bar.

**Finishing or dropping an item** moves it to the top of
[COMPLETED.md](COMPLETED.md) with its final status (`done` or
`dropped: <reason>`), and updates its row in the index. Rewrite the body of a
finished item as a record of what landed; keep `Depends on:` and `Done when:`.

**Untriaged findings go in the Inbox**, as one bullet each, without an ID.
Triaging gives a finding an ID and moves it under its area, or deletes it.

## Inbox

## Items

### 2.1 — Try noctalia as the desktop shell [tag:2.1-noctalia-shell]

**Kind:** proposal
**Status:** open
**Depends on:** none

Noctalia is a desktop shell (bar, launcher, notifications, lock screen,
wallpaper, OSD, control centre). Try it on niri without giving up the current
setup.

- **Version:** use v5 (a native rewrite configured in TOML; v5.2.1 as of
  2026-10-02) from upstream's flake (`github:noctalia-dev/noctalia`, package only).
  The nixpkgs package (4.5.0) and the noctalia wrapper in nix-wrapper-modules
  are the old Quickshell-based v4 with JSON settings.
- **What it replaces:** waybar with the theme-status widget and niri-taskbar,
  mako (it claims `org.freedesktop.Notifications`, so only one can run),
  fuzzel and `theme-menu`, swaylock (the F9/F10 binds that also lock
  KeePassXC, and earlyoom's `--avoid` list name it), and swaybg in the
  generated `style.kdl`.
- **Trying it reversibly:** a `noctalia` feature with a hot-reloaded
  `config.toml`, and a NixOS specialisation that swaps the waybar, mako and
  swaylock features for it, so switching back and forth needs no rebuild.
  The bar, launcher and lock lines move out of `config.kdl` into a generated
  include, as `style.kdl` does, so each setup brings its own.
- **Colours:** keep tinty as the source of truth. `tinty-render.sh` writes the
  active base16 palette as a noctalia custom palette
  (`~/.config/noctalia/palettes/tinty.json`, `source = "custom"`), which v5
  applies live; the work is mapping base16 onto noctalia's 16 colour roles.
  Without this, noctalia's own palette won't match the other apps.
- **NixOS options** its wifi, bluetooth, power and battery widgets need:
  `networking.networkmanager`, `hardware.bluetooth` and `services.upower` are
  on; `services.power-profiles-daemon` (or `tuned`) is not, and may conflict
  with the current `cpuFreqGovernor`/thermald setup.

**Done when:** the specialisation boots into niri with noctalia replacing the
bar, notifications, launcher, lock screen and wallpaper; locking still locks
KeePassXC; switching to and from the specialisation works without a rebuild;
and noctalia follows tinty's light/dark and scheme changes.

### 3.1 — A program to manage roadmap files [tag:3.1-roadmap-program]

**Kind:** feature
**Status:** open
**Depends on:** none

A roadmap like this one (`ROADMAP.md`, `COMPLETED.md`, `INDEX.md`), and ufo's
`roadmap.md`/`COMPLETED.md`, follow conventions that are only enforced by
hand, and keeping the index in step with the items is manual. A small program
over the format keeps them consistent:

- `new <area> <title>`: take the next free ID in the area from the index, add
  its index row and append a skeleton item to `ROADMAP.md`. No number is ever
  claimed by hand.
- `check`: IDs are unique and well formed, every item has all fields in order
  and a `Done when:`, statuses and kinds are valid, areas are declared, and
  every `Depends on:` ID exists. Against the index: every item has exactly
  one row, each row's title and file match the item, open items are in
  `ROADMAP.md` and finished or dropped ones in `COMPLETED.md`, and no row
  points at a missing item. Runs as a pre-commit hook.
- `ready`: open items whose dependencies are all done; the ordering the
  `Depends on:` lines imply, derived on demand.
- `list [--area A] [--status S] [--kind K]`: filtered views, and a count of
  open items per area so an overloaded area shows up.
- `status <id> <status>`: set an item's status, e.g.
  `in-progress (wt/noctalia)`. `done` or `dropped: <reason>` also moves the
  item to the top of `COMPLETED.md` and updates its index row.
- `dot`: the dependency graph for Graphviz.

The format additions this needs (status, kind, areas, inbox, index) are
already the conventions of these files. For ufo, the program also builds the
index ufo doesn't have yet and accepts the existing fractional IDs and tagref
tags, and its `Status:` field replaces the "Part 1 landed / Remaining" prose.
Areas there would be a declared `**Area:**` field, so existing IDs keep their
numbers.

**Done when:** the program runs `new`, `check`, `ready`, `list`, `status` and
`dot` against these files and ufo's roadmap; `check` passes on both (after
fixing what it finds, e.g. ufo's 14 steps without `Depends on:`); and it runs
as a pre-commit hook here.
