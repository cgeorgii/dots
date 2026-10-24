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

### 1.1 — Explore an ephemeral root filesystem [tag:1.1-ephemeral-root]

**Kind:** proposal
**Status:** open
**Depends on:** none

Wipe the root filesystem on every boot and keep only state that is declared
to persist, so the machine is exactly what the configuration describes and
undeclared state can't silently pile up. This is an exploration: decide
whether it's worth it, and how, before changing the disk.

- **Current layout:** a single ext4 filesystem on LUKS (`nvme0n1p2`, 1.8 TB,
  671 GB used) holds `/`, `/nix` and `/home`, with swap on a separate LUKS
  partition. Ext4 has no snapshots, so every option below needs a new
  layout, i.e. a reinstall or a careful conversion with a full backup.
- **Ways to wipe root:**
  - a tmpfs mounted at `/`, with `/nix` and a `/persist` on disk; simplest,
    but root lives in RAM;
  - btrfs subvolumes, with root rolled back to an empty snapshot in the
    initrd (with `boot.initrd.systemd`); keeps root on disk and allows
    diffing it before the rollback;
  - ZFS with a blank-snapshot rollback; the same idea, with an
    out-of-tree kernel module.
- **Declaring what persists:** the nix-community `impermanence` module, or
  its newer alternative `preservation`, mounts declared paths from
  `/persist`. Candidates on this machine: `/etc/machine-id`, SSH host keys,
  NetworkManager connections, bluetooth pairings, Mullvad's and fwupd's
  state, `/var/lib/nixos` (UID/GID allocations), and the journal.
- **Home** is a separate decision: wiping it too means listing everything
  else that has to persist (the `~/dots` checkout every out-of-store link
  points into, the KeePassXC database, the tinty state, browser profiles,
  Claude Code's config dirs, ...). Keeping `/home` persistent and wiping
  only root is the usual first step.
- **Inventory first, on the current system:** list what's written outside
  `/nix` and `/home` during normal use, e.g. as root after a few days of
  uptime:
  `find / -xdev \( -path /nix -o -path /home \) -prune -o -newer /run/booted-system -print`
  (`-prune` keeps it out of the store). That list is the persistence set,
  and it shows how big the job is before anything changes.

**Done when:** the inventory exists, a layout and persistence approach is
chosen (or the idea is dropped, with the reason), and if it goes ahead, the
migration is split into its own items.

### 1.2 — Ephemeral containers for coding agents [tag:1.2-agent-containers]

**Kind:** feature
**Status:** open
**Depends on:** none

A locked-down environment, `dev`, where a coding agent runs without access
to the main account, to escalation paths or to undeclared persistent state.
The container setup is a reusable module, so the clean room
([ref:1.5-clean-room]) is built on the same base with its own policy.

- **Containers, not host users:** declarative NixOS containers
  (`containers.agent-<name>`) with `ephemeral = true` (tmpfs root, wiped on
  container stop and on reboot), `privateNetwork = true`, and `privateUsers`
  with a fixed UID range per container, so even container root maps to an
  unprivileged host UID. Host users were rejected: they share loopback,
  `/tmp`, the process list and the host's nix-daemon.
- **Whitelist:** persistent paths are `bindMounts` from
  `/persist/agents/<name>/`, empty at first. Bind-mounted paths must be owned
  by the mapped UID. If [ref:1.1-ephemeral-root] goes ahead, `/persist/agents`
  joins its persistence set.
- **Inside `dev`:** one non-root user with a locked password, no wheel, no
  sudo, no container runtime. Packages: claude-code, direnv with nix-direnv,
  workmux (upstream, without the `gh` stub), tmux, git, gh, ripgrep, fd, jq,
  curl and a plain editor.
- **Own nix-daemon on an overlay store:** the host's daemon is not shared,
  because fixed-output derivations would let a container reach any URL from
  the host's network, bypassing [ref:1.4-egress-prompt-proxy]. Each container
  runs its own daemon on a `local-overlay` store (experimental feature
  `local-overlay-store`): the host's `/nix/store` is the read-only lower
  layer and `/persist/agents/<name>/nix` the writable upper layer, combined
  with OverlayFS. Its builders run in the container's network namespace. The
  upper layer persists only as a cache and needs occasional GC. Fallback if
  the overlay store proves unreliable: an empty container store with the
  system closure registered at start (`closureInfo` + `nix-store --load-db`)
  and the host's store served by harmonia, signed by a host-only key, as the
  first substituter. The host never trusts a container's store.
- **Attaching:** a host script, `agent <name>`, starts the container if
  needed and runs `machinectl shell <user>@agent-<name>` into
  `tmux new -A -s main`.
- **Limits:** `MemoryMax`, `CPUQuota` and `TasksMax` on each container's
  unit, so a runaway agent can't OOM the desktop session.
- **Kernel sysctls** on the host: `kptr_restrict=2`,
  `kernel.unprivileged_bpf_disabled=1`, `perf_event_paranoid=3`
  (`ptrace_scope=1` and `dmesg_restrict=1` are already set).

**Done when:** `agent dev` attaches to tmux in its container; files outside the whitelist are gone after a container restart
and after a reboot; the agent user can't become root, and container root is
an unprivileged UID on the host; `nix develop` and direnv work inside, with
host store paths available without copying and builds running in the
container's network namespace.

### 1.3 — Agent tokens through sops-nix [tag:1.3-agent-secrets]

**Kind:** feature
**Status:** open
**Depends on:** [ref:1.2-agent-containers]

The `dev` agent needs a GitHub token to push and open PRs, and a Claude Code
token so an ephemeral container doesn't need a login after every start. The
clean room ([ref:1.5-clean-room]) gets no GitHub token; its only secret is
the VPN profile and credentials.

- **GitHub:** a fine-grained personal access token for `dev`, limited
  to selected repositories, with `Contents: RW`, `Pull requests: RW`,
  `Metadata: R` and an expiry date. Branch rulesets on those repositories
  keep the default branch protected, so a token can push branches and open
  PRs but not push to `main`. The token's scope is the real protection:
  whatever the agent can read, it can exfiltrate.
- **Claude Code:** a long-lived token from `claude setup-token`, provided as
  `CLAUDE_CODE_OAUTH_TOKEN`.
- **Delivery:** sops-nix with a dedicated age key at
  `/var/lib/sops-nix/key.txt` (sshd isn't enabled, so there is no host key to
  derive one from; the key joins the persistence set if
  [ref:1.1-ephemeral-root] goes ahead). Secrets decrypt to `/run/secrets/`,
  owned by the container's mapped UID, mode `0400`, never in the store, and
  are bind-mounted read-only into their container. Inside, `GH_TOKEN` is
  read from the file and git uses `gh auth git-credential`.

**Done when:** encrypted secrets are in the repository; each container sees
only its own tokens; `gh pr create` and `git push` to a branch work from
inside `dev` and a push to a protected branch is rejected; Claude Code
starts logged in after a container restart.

### 1.4 — An egress proxy that prompts per host [tag:1.4-egress-prompt-proxy]

**Kind:** feature
**Status:** open
**Depends on:** [ref:1.2-agent-containers]

Network access from the `dev` container is approved per hostname, with a
prompt on the desktop like the one for SSH key use.

- **Enforcement:** each container's firewall allows only the proxy's port on
  the host side of its veth link, plus DNS if needed. `HTTPS_PROXY` and
  `HTTP_PROXY` are set inside; tools that ignore them can't connect at all.
  The container's nix-daemon (see [ref:1.2-agent-containers]) is behind the
  same rule.
- **Per hostname, not per IP:** the proxy reads the host from the
  `CONNECT host:port` line, so it needs no TLS interception, and CDN-hosted
  services still get one meaningful prompt.
- **Prompt:** an unknown host opens a zenity dialog naming the container and
  `host:port`, with Deny (the default focus), Allow once and Always. No
  answer within a timeout means deny, so an unattended agent doesn't hang.
- **Allowlists:** one per container, a hot-reloaded file in the repository.
  Always appends to it, so approvals are reviewed in git. `dev`'s is seeded
  with `api.anthropic.com`, `github.com`, `api.github.com`, the GitHub
  download hosts and `cache.nixos.org`.
- **Process:** a small script packaged with its dependencies, run as a
  systemd user service in the desktop session so it can show dialogs.
  OpenSnitch was considered and rejected: it matches traffic by local
  process and IP, and forwarded container traffic has no local process.

**Done when:** a container reaches allowlisted hosts with no prompt; an
unlisted host prompts, and Deny, Allow once, Always and a timeout behave as
described; Always lands in that container's allowlist file; a direct
connection that bypasses the proxy fails.

### 1.5 — A clean room for sensitive data [tag:1.5-clean-room]

**Kind:** feature
**Status:** open
**Depends on:** [ref:1.2-agent-containers], [ref:1.3-agent-secrets]

`acid-helmet` is a container for working on sensitive data on a remote
system reached over a Sophos VPN. Data goes in, and nothing comes out except
over that VPN. It is built on the container module from
[ref:1.2-agent-containers], with the opposite threat model: what matters is
that the data can't leak, to the internet, to the `dev` container or to the
rest of the desktop.

- **No way out:** no outbox, no shared clipboard, no GitHub token, nothing
  bind-mounted writable from the host except the vault below. The only view
  of the data from outside is the attached tmux session.
- **VPN client:** Sophos Connect has no Linux client. The same Sophos
  Firewall VPN is reachable with OpenVPN, using the `.ovpn` profile from the
  Sophos user portal (SSL VPN), or with strongSwan for IPsec. Which one is
  still open: check what the user portal offers. Either way the client runs
  inside the container as container root (with a TUN device,
  `enableTun = true`, for OpenVPN); the agent user can't read its
  credentials. Profile and credentials come from [ref:1.3-agent-secrets].
- **One-time password:** the VPN almost certainly requires one, so it can't
  start unattended. `agent acid-helmet` asks for the code, along with the
  vault passphrase, through `systemd-ask-password`, and starts the VPN with
  it.
- **Network:** the only allowed destination is the VPN endpoint. A
  forward-chain rule on the host, on the container's veth, allows its
  IP and port and drops everything else, so container root can't bypass it.
  DNS goes through the tunnel. If the endpoint is a hostname, its IP is
  pinned in the rule. Mullvad on the host blocks or tunnels this traffic,
  so it needs a split-tunnel or firewall exception for the endpoint, or the
  VPN runs inside Mullvad. Later option: run OpenVPN on the host
  (`--ifconfig-noexec --route-noexec`) and move its TUN device into the
  container, so the container has no veth at all.
- **Agent:** undecided. The container is built so Claude Code can be added
  later, but that means allowing `api.anthropic.com` and sending the data
  to Anthropic's API, which has to be acceptable for the data in question.
- **Nix:** the container's own daemon on the overlay store, as in
  [ref:1.2-agent-containers], with no substituter beyond the host's store
  and no network for builds. Tools are built on the host and come in through
  the lower layer.
- **Vault:** the persistent workspace is encrypted separately from the
  disk's LUKS, e.g. a LUKS image under `/persist/agents/acid-helmet/`,
  opened by a system unit the container requires, with the passphrase asked
  through `systemd-ask-password` when `agent acid-helmet` starts it, and
  closed when the container stops. While locked, nothing on the machine can
  read it. While open, host root can, which is unavoidable.
- **Data in:** a read-only inbox bind-mounted from the host. Files are
  moved into the vault from inside.
- **No plaintext on disk:** `MemorySwapMax=0` on the container's unit, so
  the tmpfs root and process memory aren't swapped out.

**Done when:** `agent acid-helmet` asks for the vault passphrase and the VPN
one-time password, opens the vault, connects the VPN from inside and attaches
to tmux; the vault is closed after the container stops; the container can
reach nothing but the VPN endpoint, before and after the tunnel is up; the
inbox is read-only inside and there is no writable path from the container
to the host other than the vault; the `dev` container can't reach it.

### 2.1 — Try noctalia as the desktop shell [tag:2.1-noctalia-shell]

**Kind:** proposal
**Status:** in-progress (master)
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
