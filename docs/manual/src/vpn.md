# VPN

The work VPN is a NetworkManager OpenVPN connection named `work`, declared in
`modules/system/vpn/vpn.nix`. Noctalia lists it under **VPNs** in the control
centre's network tab and shows a shield in the bar while it is up.

The tunnel asks for a password with a one-time code on every connect.
Noctalia can only answer NetworkManager's Wi-Fi password prompts, so starting
the tunnel from the panel fails. Connect from a terminal instead with
`nmcli --ask`, which prompts for the secrets itself. Disconnecting works from
either place.

## Connecting

```sh
nmcli --ask connection up work
```

At the password prompt, type the password with the current OTP appended and
no separator (`hunter2123456`). There is no separate prompt for the code.

Check the tunnel is up with `nmcli connection show --active`, or look for the
VPN shield in the bar.

## Disconnecting

Toggle it off under **VPNs** in noctalia, or:

```sh
nmcli connection down work
```

## How the profile is stored

The connection was translated by hand from the Sophos user portal's `.ovpn`
export. Its inline blocks became files in `modules/system/vpn/`:

- `<ca>` → `work-ca.crt`, the public CA chain that checks the server.
- `<cert>` → `work.crt`, my client certificate. It is public.
- `<key>` → `work.key.sops`, my private key, encrypted (see
  [Secrets](secrets.md)).

The other directives map onto `vpn` settings in `vpn.nix`. NetworkManager
writes the profile to `/run/NetworkManager/system-connections/` at boot, so
changes made with `nmcli connection modify` last until the next reboot.

## A new profile from the provider

When the portal issues a new `.ovpn`, re-extract the blocks (`$f` is the
export):

```sh
cd modules/system/vpn
sed -n '/^<ca>/,/^<\/ca>/{/^<\/\?ca>/!p}' "$f" > work-ca.crt
sed -n '/^<cert>/,/^<\/cert>/{/^<\/\?cert>/!p}' "$f" > work.crt
sed -n '/^<key>/,/^<\/key>/{/^<\/\?key>/!p}' "$f" \
  | sops encrypt --input-type binary --output-type binary \
      --filename-override modules/system/vpn/work.key.sops /dev/stdin \
  > work.key.sops
```

Compare its other directives with `vpn.nix`, rebuild, and delete the export.

## Mullvad

Mullvad runs its own daemon, not a NetworkManager connection, and its
firewall blocks traffic that bypasses its tunnel. Disconnect Mullvad before
bringing up the work tunnel.
