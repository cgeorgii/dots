# The desktop shell

Noctalia draws everything around niri: the bar, launcher, notifications, lock
screen and wallpaper. It runs as the `noctalia` user service, so
`systemctl --user restart noctalia` restarts it. Apps started from its
launcher run as their own units and survive the restart.

| Key | Action |
| --- | --- |
| `Mod+Space` | Launcher |
| `Mod+S` | Control centre |
| `F9` | Lock, which also locks KeePassXC |
| `F10` | Lock and suspend |

## Configuration

Both files live in `modules/desktop/noctalia/` and are hot-reloaded:

- `config.toml` is written by hand: the bar layout, widgets and hooks.
- `settings.toml` is what noctalia's Settings window saves. It is linked into
  the checkout, so changes made in the GUI show up in `git status`. Commit
  them to keep them. It loads last, so it wins over `config.toml`.

Colours, light/dark and the wallpaper come from tinty; see
[Themes](themes.md).
