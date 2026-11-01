# Switching the desktop shell

<!-- [ref:desktop-shell] -->

The `desktop.shell` option picks what runs around niri:

- `classic`: waybar, mako, fuzzel, swaylock and swaybg.
- `noctalia`: the noctalia shell, which replaces all of them.

The default system is classic. The `noctalia` specialisation in
`modules/hosts/coco/configuration.nix` sets the option to noctalia, so one
rebuild builds both, and switching between them needs no further rebuild.

## At boot

Pick the `noctalia` entry in the systemd-boot menu. The plain entry is
classic.

## Live, without rebooting

To noctalia:

```sh
sudo /nix/var/nix/profiles/system/specialisation/noctalia/bin/switch-to-configuration switch
```

Back to classic:

```sh
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

Both switch the running system only: the boot default stays classic.

## Rebuilding while on noctalia

A plain `nixos-rebuild switch` activates the default system, so it puts you
back on classic. To rebuild and stay on noctalia:

```sh
sudo nixos-rebuild switch --specialisation noctalia
```
