# Neovim

The config lives in `modules/editor/neovim/nvim/` and is linked to
`~/.config/nvim`, so edits there apply the next time neovim starts. No
rebuild is needed.

The leader key is `;`. Press it and wait to get which-key's menu of
everything under it.

## Plugins with lazy.nvim

lazy.nvim installs plugins and checks for updates. Plugins are listed in
`init.lua`. The pinned versions are in `lazy-lock.json` in the same directory,
which is tracked in git.

| Key / command | Action |
| --- | --- |
| `:Lazy` | Open the plugin manager |
| `;CR` | `:Lazy sync`: install, clean and update |
| `;CE` | Open `init.lua` in a new tab |

Keys inside the `:Lazy` window:

| Key | Action |
| --- | --- |
| `I` | Install missing plugins |
| `U` | Update plugins and rewrite the lockfile |
| `S` | Sync: install, clean, then update |
| `X` | Clean: remove plugins no longer in the spec |
| `C` | Check for updates without applying them |
| `R` | Restore every plugin to the commit in the lockfile |
| `L` | Show the log of recent changes |
| `P` | Profile startup time |
| `<CR>` | Expand the plugin under the cursor |
| `?` | Help |
| `q` | Close |

Because the lockfile is in the checkout, `U` and `S` change a tracked file.
Commit `lazy-lock.json` after updating and checking that things still work. If
an update breaks something, run `git checkout` on the lockfile and press `R`.

The update check runs in the background but does not pop up notifications.
Open `:Lazy` to see whether updates are waiting. If you edit `init.lua` while
neovim is running, lazy notices and reloads the spec.

### Plugins outside lazy

- Tree-sitter parsers are installed the first time a file of that language
  is opened. `:TSUpdate` updates them.
- `ufo-nvim` is loaded from `~/.local/share/nvim/ufo-nvim`, which lazy does
  not manage. Build it from the ufo repo:

  ```sh
  nix build .#ufo-nvim -o ~/.local/share/nvim/ufo-nvim
  ```

## Finding things

| Key | Action |
| --- | --- |
| `<C-p>` | Git-tracked files (fzf-lua) |
| `<C-\>` or `;sf` | All files |
| `;sg` | Ripgrep the project |
| `;sb` or `;bb` | Open buffers |
| `;sd` or `;bs` | Lines in the current buffer |
| `;sh` | Help tags |
| `gk` | Ripgrep the word under the cursor, or the visual selection, into the quickfix list |
| `*` / `#` | Swapped: `*` searches backwards, `#` forwards |

In the fzf.vim pickers, `ctrl-t`, `ctrl-s` and `ctrl-v` open the pick in a
tab, a split or a vertical split, and `ctrl-/` toggles the preview.

### Search and replace

grug-far opens a project-wide find-and-replace buffer.

| Key | Action |
| --- | --- |
| `\` or `;srr` | Open grug-far |
| `;srw` | Prefilled with the word under the cursor |
| `;srf` | Limited to the current file |

## Files, tabs and windows

| Key | Action |
| --- | --- |
| `<C-n>` | Toggle the floating file tree |
| `<C-f>` | Reveal the current file in the tree |
| `;t` | New tab |
| `;h` / `;l` | Previous / next tab |
| `;q` | Close tab |
| `<C-h/j/k/l>` | Move between windows, crossing into zellij or tmux panes |
| `<C-w>z` | Toggle zoom on the current window, like tmux's `C-s z` |
| `;rr` | Reload the buffer from disk, dropping changes |

## Editing

| Key | Action |
| --- | --- |
| `H` / `L` | First / last non-blank character on the line |
| `;a` | Toggle an argument list between one line and one per line |
| `;ff` | Format the file with conform (fourmolu, stylua, nixfmt) |
| `;f` (visual) | Format the selection |
| `gc` | Comment (vim-commentary) |
| `ys`, `cs`, `ds` | Add, change or delete surroundings (vim-surround) |
| `<C-t>` (insert) | Insert a git-tracked filename picked with fzf |

Formatting is never done on save. Run `;ff` when you want it.

### Clipboard

Yanks go to the system clipboard by default. `;cc` switches between the
system clipboard and vim's own registers, and the status line shows which
one is in use. `;bc` copies the whole buffer to the system clipboard.

### Completion

| Key | Action |
| --- | --- |
| `<C-Space>` | Open completion |
| `<CR>` | Accept the selected item, or the first one |
| `<C-e>` | Abort |
| `<C-b>` / `<C-f>` | Scroll the documentation window |

## Diagnostics and LSP

| Key | Action |
| --- | --- |
| `;n` | Next diagnostic |
| `;N` or `;p` | Previous diagnostic |

These are set only in Nix and Haskell buffers:

| Key | Action |
| --- | --- |
| `gd`, `gy`, `gi`, `gr` | Definition, type definition, implementation, references |
| `;k` | Hover documentation |
| `;rn` | Rename symbol |
| `<Space>ca` | Code actions |

### Haskell

HLS does not attach on its own. Start it with `:Hls start` and stop it
with `:Hls stop`. On top of the LSP keys above, Haskell buffers get:

| Key | Action |
| --- | --- |
| `;qq` | Code actions |
| `<Space>cl` | Run the code lens on this line |
| `<Space>ea` | Evaluate all code lenses |
| `<Space>hs` | Hoogle search for the signature under the cursor |
| `;rr` | Toggle a GHCi REPL (instead of reloading the buffer) |
| `;rf` | Toggle a REPL for the current file |
| `;rq` | Quit the REPL |

`;q` closes the tab in Haskell buffers too, but it waits for `timeoutlen` in
case you are typing `;qq`.

In Haskell projects, saving `package.yaml` runs `hpack`.

## Markdown

Markdown buffers are rendered in place.

| Key | Action |
| --- | --- |
| `m` | Toggle rendering |
| `z` | Toggle zen mode |

These keys replace `m` (set mark) and the `z` prefix (folds, `zz`) in
markdown buffers only.
