Installation
------------
Symlink this folder into /etc/nixos using sudo:

    ❯ sudo ln -s /home/cgeorgii/projects/dots/nixos/* /etc/nixos

Run `sudo nixos-rebuild switch`.

Configuring git
---------------

### Using HTTPS with git-credential-manager

The dotfiles include configuration for secure credential storage using git-credential-manager and pass-secret-service:

1. Initialize the password store (only needed once):
   ```
   $ pass init YOUR_GPG_KEY_ID
   ```

2. Authentication workflow:
   - First-time authentication: You'll be prompted to enter a Personal Access Token (PAT)
   - PAT is securely stored in the pass password store via GPG encryption
   - Future authentications will use the stored PAT automatically
   - No browser-based auth - uses CLI-based token entry only

3. The configuration in home/cgeorgii.nix includes:
   ```nix
   credential = {
     helper = "manager";
     credentialStore = "gpg";
   };
   ```

Theming (light/dark + colour schemes)
-------------------------------------

Colours are driven at runtime by [tinty], so the theme can change without a
rebuild. `tinty apply` exports the active [base16]/[base24] palette into the
environment and runs `coco/dotfiles/bin/tinty-render.sh`, which regenerates each
app's config and live-reloads it. The scheme catalogue is the
`tinted-theming/schemes` flake input (a read-only, offline copy — `tinty sync`
is never run).

### Switching light/dark

`darkman` flips automatically at Berlin sunrise/sunset, applying the configured
defaults (`darkDefault` / `lightDefault` in `coco/home/theme.nix`). To switch
by hand:

```
$ darkman toggle          # flip light <-> dark now
$ darkman set light       # force a mode
$ darkman get             # show the current mode
```

### Picking any scheme

```
$ theme-menu                              # fuzzel picker over all 500+ schemes
$ tinty apply base16-catppuccin-mocha     # apply a specific scheme
$ tinty list                              # list every scheme id
```

A manual pick lasts until darkman's next sun event, which reapplies a default.
Change `darkDefault` / `lightDefault` in `coco/home/theme.nix` to make a scheme
stick as the automatic choice.

### What follows the theme

**Any scheme** (full palette): kitty, waybar, lazygit, fuzzel, nvim (all live).
**Light/dark variant only** (no per-scheme equivalent exists): delta, tmux, and
GTK apps — these flip between the gruvbox light/dark variants and follow the
`org.gnome.desktop.interface color-scheme` preference. Claude Code (`"theme":
"auto"`) follows the terminal background, so it tracks kitty.

To tweak how a scheme maps onto an app, edit
`coco/dotfiles/bin/tinty-render.sh` — it is a hot dotfile and takes effect on the
next `tinty apply` (no rebuild).

[tinty]: https://github.com/tinted-theming/tinty
[base16]: https://github.com/tinted-theming/schemes/tree/HEAD/base16
[base24]: https://github.com/tinted-theming/schemes/tree/HEAD/base24

Connecting to Wi-Fi
------------------

### Using NetworkManager TUI
1. Open the network manager interface:
   ```
   $ nmtui-connect
   ```

2. Select your Wi-Fi network from the list
3. Enter the network password when prompted

### Handling Captive Portals (Hotel/Airport Wi-Fi)
For networks that require browser login (captive portals):

1. Connect to the network using nmtui-connect first
2. Open the captive portal browser:
   ```
   $ captive-browser
   ```
3. Complete the login process in the browser window that opens

### Troubleshooting Connection Issues
- If experiencing connection problems, try disabling any active VPN connections first
- VPNs can interfere with initial network authentication and captive portal access
- Re-enable VPN after successfully connecting to the network

ZSA Keyboard Firmware Flashing
------------------------------

This system includes support for ZSA keyboards (Ergodox EZ, Moonlander, etc.) with the Wally CLI tool for firmware updates.

### Flashing Firmware
1. Download your firmware file (.bin) from [ZSA Oryx](https://configure.zsa.io/)
2. Connect your keyboard via USB
3. Put the keyboard in flash mode:
   - **Moonlander**: Press and hold the small button on the left side while plugging in
4. Flash the firmware:
   ```
   $ wally-cli path/to/your/firmware.bin
   ```

### Example Usage
```bash
# Download firmware from Oryx and flash it
$ cd ~/Downloads
$ wally-cli moonlander_layout_v2.bin
Flashing ZSA keyboard...
Device found: Moonlander
Flashing firmware... done!
```

### Troubleshooting
- If the device isn't detected, ensure it's in flash mode (small button pressed during connection)
- USB permissions are automatically configured through the ZSA udev rules
- The keyboard will restart automatically after successful flashing

Configuring fingerprint reader
------------------------------
  1. Run `fprintd-enroll`
  2. Profit
