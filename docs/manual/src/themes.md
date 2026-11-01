# Themes

<!-- [ref:scheme-marks] -->

darkman flips between light and dark at Berlin sunrise and sunset. Each time
it applies one scheme from the kept schemes of that variant, a different one
per day. The kept schemes are the `keep` lines in
`modules/desktop/theme/scheme-marks`.

Toggle light and dark by hand with `darkman toggle`, or left-click the theme
button in the bar.

## Picking and triaging schemes

`theme-menu` (right-click the theme button) lists the schemes in fzf, each
with its mark and its variant. The header shows the active scheme and the two
filters, view and variant, which combine. Hovering the theme button also
names the active scheme.

Navigation is vim-style: the list opens without a search input, so keys act
on the list until `/` starts a search.

| Key            | Action                                                 |
|----------------|--------------------------------------------------------|
| `j` / `k`      | move down / up                                         |
| `g` / `G`      | first / last                                           |
| `ctrl-d` / `ctrl-u` | half a page down / up                             |
| `/`            | search; `enter` keeps the query, `esc` clears it       |
| `enter`        | apply the scheme; the list stays open                  |
| `space`        | cycle the mark: unmarked, keep, skip                   |
| `tab`          | cycle the view: kept, unreviewed, all                  |
| `ctrl-t`       | cycle the variant: both, dark, light                   |
| `q` / `esc`    | close                                                  |

It opens on the kept view. To triage new schemes, switch to the unreviewed
view, apply one with `enter` to see it, and mark it with `space`. Marked rows
stay listed, showing their new mark, until a filter changes.

Marks apply at once, without a rebuild. A scheme applied by hand lasts until
darkman's next sun event. Commit `scheme-marks` to keep the marks.
