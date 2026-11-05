# File manager

Dolphin is the default file manager. Double-clicking an archive opens it as a
folder.

## Configuration

`modules/desktop/dolphinrc` is what Dolphin's settings window saves. It is linked
into the checkout, so changes made in the GUI show up in `git status`. Commit
them to keep them. `modules/desktop/user-places.xbel` does the same for the
sidebar places.

Colours, icons and fonts come from `kdeglobals`, which tinty rewrites on every
theme change; see [Themes](themes.md). Anything Dolphin saves there is lost at
the next change, so set it in `tinty-render.sh` instead.

Window size and layout stay out of the repo, in
`~/.local/state/dolphinstaterc`.
