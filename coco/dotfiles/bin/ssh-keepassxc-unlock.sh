#!/usr/bin/env bash
# Run from ssh_config `Match exec`. If the agent is up but holds no keys
# (KeePassXC locked or not running), open KeePassXC's unlock dialog and wait
# until it loads the keys. Always exits 1 so the Match block never applies.
#
# Usage: ssh-keepassxc-unlock [user@host]

db="$HOME/Dropbox/Apps/Keepass2Android/passbook.kdbx"
timeout=60
dest="${1:-}"

[ -n "$WAYLAND_DISPLAY" ] || exit 1

# ssh-add -l: 0 = keys loaded, 1 = agent empty, 2 = no agent
ssh-add -l >/dev/null 2>&1
[ $? -eq 1 ] || exit 1

# Describe what triggered ssh: the process that started it (e.g. `git push`),
# or ssh's own command line when it was run straight from a shell.
context() {
  local pid=$$ parent comm cmd cwd
  while [ "$pid" -gt 1 ] && [ "$(ps -o comm= -p "$pid")" != ssh ]; do
    pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
  done
  [ "$pid" -gt 1 ] || return

  parent=$(ps -o ppid= -p "$pid" | tr -d ' ')
  comm=$(ps -o comm= -p "$parent")
  case "$comm" in
    sh | bash | zsh | dash | fish) cmd=$(ps -o args= -p "$pid") ;;
    *) cmd=$(ps -o args= -p "$parent") ;;
  esac
  cwd=$(readlink "/proc/$parent/cwd")
  printf '%.120s\nin %s' "$cmd" "${cwd/#$HOME/\~}"
}

body="$(context)"
[ -n "$dest" ] && body="$body → $dest"
body=$(printf '%s' "$body" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

echo "ssh: agent is empty, unlock KeePassXC..." >&2
notif=$(notify-send -p -a ssh -i dialog-password -t $((timeout * 1000)) \
  "SSH key requested" "$body" 2>/dev/null)
setsid -f keepassxc "$db" >/dev/null 2>&1

close_notif() {
  [ -n "$notif" ] && busctl --user call org.freedesktop.Notifications \
    /org/freedesktop/Notifications org.freedesktop.Notifications \
    CloseNotification u "$notif" >/dev/null 2>&1
}

# Wayland won't let KeePassXC raise itself; ask niri to focus it (it may still
# be starting up).
for _ in $(seq 20); do
  id=$(niri msg --json windows 2>/dev/null |
    jq -r 'first(.[] | select(.app_id == "org.keepassxc.KeePassXC") | .id) // empty')
  if [ -n "$id" ]; then
    niri msg action focus-window --id "$id" >/dev/null 2>&1
    break
  fi
  sleep 0.25
done

for _ in $(seq $((timeout * 2))); do
  sleep 0.5
  if ssh-add -l >/dev/null 2>&1; then
    close_notif
    exit 1
  fi
done

echo "ssh: timed out waiting for KeePassXC" >&2
exit 1
