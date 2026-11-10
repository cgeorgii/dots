#!/usr/bin/env bash
# SOPS_AGE_KEY_CMD: prints my age identity from its KeePassXC entry, so it is
# never on disk. sops runs this with stdin on /dev/null and stderr captured,
# so the database password is asked for in a dialog.
#
# Usage: sops-age-key

db="$HOME/Dropbox/Apps/Keepass2Android/passbook.kdbx"
# SOPS_AGE_KEY_ENTRY picks another entry, e.g. per repository from direnv
entry="${SOPS_AGE_KEY_ENTRY:-sops age key}"

fail() {
  zenity --error --title "sops" --text "$1" --no-markup 2>/dev/null
  echo "sops-age-key: $1" >&2
  exit 1
}

[ -n "$WAYLAND_DISPLAY" ] || fail "no display to ask for the KeePassXC password"

pass=$(zenity --entry --hide-text --title "sops" --no-markup \
  --text "KeePassXC password, to decrypt secrets with the \"$entry\" entry") ||
  exit 1

printf '%s\n' "$pass" |
  keepassxc-cli show -q -s -a Password "$db" "$entry" 2>/dev/null ||
  fail "could not read \"$entry\" from $db"
