# Zellij

Zellij is the terminal multiplexer, set up to behave like the old tmux
configuration: `C-s` is the prefix, and `C-h/j/k/l` move between panes and
on into Neovim windows. The keybindings are in
`modules/terminal/zellij/config.kdl`, which is linked into the checkout, so
edits apply to running sessions straight away.

## Zoom

`C-s z` zooms the focused pane. Moving with `C-h/j/k/l` leaves the zoom and
focuses the neighbour, as in tmux; zellij on its own would zoom the
neighbour instead. With floating panes showing, the keys move between them and
the zoom stays.

## Leaving a stack

`C-h/j/k/l` step through a stack one pane at a time. `M-j` and `M-k` skip the
rest of it, focusing the pane (or stack) below or above the focused stack;
outside a stack they move like `C-j` and `C-k`. They work in Neovim too.

Moving focus out of Neovim leaves locked mode at once, so `C-j` pressed again
straight away moves on rather than reaching the shell. When the new pane runs
Neovim, autolock locks it again a moment later.

## Moving panes into stacks

`C-S-h/j/k/l` moves the focused pane, building stacks the way a Rommé player
melds cards: pressed on the bottom of two panes, `C-S-k` stacks it with the one
above, and pressed again swaps the two. In general:

- Up and down move the pane one place through its stack. At the edge of the
  stack it joins the neighbour in that direction (a pane, or a stack it
  becomes part of), entering on the side it came from: at the bottom when
  moving up, at the top when moving down.
- Left and right always leave the column and join the neighbour at the bottom
  of its stack.
- With no neighbour in that direction nothing happens: zellij can't break a
  pane out of a stack on a chosen side.

The pane stays focused and shown throughout. When several panes border it,
the one focused most recently is joined, as with `C-h/j/k/l`. The keys work in
locked mode too, so inside Neovim as well. They rely on zellij showing stacks
as lists (`stacked_pane_list`, on by default); moving is off while a pane is
zoomed or floating panes are showing.

## Tab names

A tab is named after its focused pane's title, cut to 24 characters, and
follows it as focus and titles change. At a shell prompt the title is the
directory; while a command runs it is the command line; programs such as
Neovim set their own.

Renaming a tab with `C-s ,` fixes its name. To hand it back to automatic
naming, rename it to nothing: `C-s ,` then `Enter` on the empty name.

Tools that mark a tab with a status icon keep their mark: the icon sits
between the invisible characters U+2063 and U+2064, and the renaming leaves it
in place. Claude Code's hooks mark the tab of each agent with
`zellij-agent-status`: working, waiting for an answer, or done.

## The plugins

Each behaviour is a small plugin in the Cargo workspace under
`modules/terminal/zellij/plugins/`: `meld` for the zoom and for moving panes
into stacks, `autoname` for the tab names. They are installed as `~/.config/zellij/plugins/<name>.wasm` and
loaded in the background by `load_plugins` in `config.kdl`; removing one there
turns its behaviour off. The status bar, `bar`, is the layout's instead, but
it too is configured under its alias in `config.kdl`. Unlike the KDL files
the plugins are built by Nix, so changes need a rebuild, and running sessions
only pick up a new build once restarted.

The first time a session loads each one, zellij asks to grant it permissions;
accept with `y`. Their tests run with `nix flake check`, which also fails when
nixpkgs moves zellij to a version the workspace's `zellij-tile` dependency
doesn't match: bump it in `plugins/Cargo.toml` and update `Cargo.lock` with
`cargo update -p zellij-tile`.
