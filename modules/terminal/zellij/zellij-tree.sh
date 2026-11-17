#!/usr/bin/env bash
# tmux choose-tree style session/tab picker for zellij, built on fzf.
#
# Starts in navigation mode (j/k move, l/h expand/collapse, J/K reorder, enter
# switches); `/` shows the query box and expands every session, esc goes back.
#
#   zellij-tree                  run the picker (usually inside a floating pane)
#   zellij-tree list [--all]     print the tree, tab-separated: session, tab, label
#   zellij-tree refresh          print the tree and keep it for the next pick
#   zellij-tree preview S [T]    print the focused pane of session S, tab T
#   zellij-tree expand|collapse  fzf actions for the line under the cursor
#   zellij-tree move S T ID DIR  fzf actions moving that line down or up
#   zellij-tree branch           print the git branch of $PWD for the status bar
#   zellij-tree here [DIR]       attach or switch to a session named after DIR ($PWD)
#   zellij-tree root             make $PWD the current session's root
#
# Each session has a root directory, which new shells in it start in (see the
# zsh hook in zellij.nix) rather than in the focused pane's directory.
set -euo pipefail

current="${ZELLIJ_SESSION_NAME:-}"
self=$(realpath "${BASH_SOURCE[0]}")
# Sessions whose tabs are shown, one per line; set up by `pick`.
state="${ZELLIJ_TREE_STATE:-/dev/null}"
# One file per session holding its root; the zsh hook reads the same path.
roots="${XDG_RUNTIME_DIR:-/tmp}/zellij-roots"
# The picker's last list, per attached session (it marks that one)
cache="${XDG_RUNTIME_DIR:-/tmp}/zellij-tree/list.$current"
# Session names in the order the picker lists them, one per line
order="${XDG_RUNTIME_DIR:-/tmp}/zellij-tree/order"

set_root() {
  mkdir -p "$roots"
  printf '%s\n' "$2" >"$roots/$1"
}

# Live sessions only, as exited ones can't be listed or previewed: in the order
# set in the picker (see move_session), then the ones it hasn't placed, oldest
# first.
sessions() {
  local live
  live=$(zellij list-sessions --no-formatting 2>/dev/null |
    grep -v 'EXITED' |
    awk '{ print $1 }')
  [[ -n $live ]] || return 0
  {
    grep -xFf <(printf '%s\n' "$live") "$order" 2>/dev/null || true
    printf '%s\n' "$live"
  } | awk '!seen[$0]++'
}

# The tree, with the first ten lines numbered (0)-(9) for the digit keys, like
# tmux; searching (--all) drops the numbers since the matches reorder.
list() {
  if [[ -n ${1:-} ]]; then
    tree --all
  else
    tree | awk -F'\t' -v OFS='\t' 'NR <= 10 { $3 = "\033[2m(" NR - 1 ")\033[0m " $3 } { print }'
  fi
}

tree() {
  local all=${1:-} s ss open tmp i
  mapfile -t ss < <(sessions)
  # Query every session's tabs at once: each query is a round trip to its server
  tmp=$(mktemp -d -t zellij-tree.XXXXXX)
  for i in "${!ss[@]}"; do
    zellij --session "${ss[i]}" action list-tabs --json >"$tmp/$i" 2>/dev/null &
  done
  wait
  for i in "${!ss[@]}"; do
    s=${ss[i]}
    open=false
    if [[ -n $all ]] || grep -qxF "$s" "$state" 2>/dev/null; then
      open=true
    fi
    jq -rs --arg s "$s" --argjson open "$open" --argjson attached "$([[ $s == "$current" ]] && echo true || echo false)" '
      (first // []) | sort_by(.position) | (length - 1) as $last |
      "\($s)\t\t\(if $open then "▾" else "▸" end) \u001b[1;34m\($s)\u001b[0m: \(length) tabs\(if $attached then " \u001b[2m(attached)\u001b[0m" else "" end)",
      (if $open then to_entries[] |
        "\($s)\t\(.value.position)\t    \(if .key == $last then "└─" else "├─" end) \(.value.position + 1): \(.value.name)\(if .value.active then " \u001b[33m*\u001b[0m" else "" end)\t\(.value.tab_id)"
      else empty end)
    ' "$tmp/$i"
  done
  rm -rf "$tmp"
}

# The pane on screen for a line. fzf asks again when a reload changes the line
# under the cursor, as moving a session does; the screen is the same, so the
# last preview is kept and reused rather than asked of zellij again.
preview() {
  local key="$1/${2:-}" last="$state.preview"
  if [[ -f $last && $(head -n1 "$last") == "$key" ]]; then
    tail -n +2 "$last"
    return
  fi
  { printf "%s\n" "$key"; capture "$@"; } >"$last.tmp"
  mv "$last.tmp" "$last"
  tail -n +2 "$last"
}

capture() {
  local s=$1 tab=${2:-} panes pane tabs
  # A session line previews its active tab: ask for the tabs alongside the
  # panes, as each query is a round trip
  if [[ -z $tab ]]; then
    tabs=$(mktemp -t zellij-tree.XXXXXX)
    zellij --session "$s" action list-tabs --json >"$tabs" 2>/dev/null &
  fi
  panes=$(zellij --session "$s" action list-panes --json --all 2>/dev/null) || {
    echo "session $s is not reachable"
    return
  }
  if [[ -z $tab ]]; then
    wait
    tab=$(jq -r 'map(select(.active)) | first | .position // 0' "$tabs" 2>/dev/null || echo 0)
    rm -f "$tabs"
  fi
  # Prefer the focused terminal pane of the tab, falling back to any terminal pane.
  pane=$(jq -r --argjson t "$tab" '
    map(select(.tab_position == $t and (.is_plugin | not) and (.exited | not)))
    | (map(select(.is_focused)) + .) | first | .id // empty
  ' <<<"$panes")
  if [[ -z $pane ]]; then
    echo "no terminal pane in this tab"
    return
  fi
  zellij --session "$s" action dump-screen --ansi --pane-id "terminal_$pane" 2>/dev/null |
    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# The navigation-mode list fzf shows is kept in $state.list, so that moving a
# session can rewrite it without asking every session for its tabs again.

# Print the list, keeping it as the cache for the next run.
refresh() {
  local tmp
  mkdir -p "${cache%/*}"
  tmp=$(mktemp "$cache.XXXXXX")
  list >"$tmp"
  mv "$tmp" "$cache"
  show "$cache"
}

# Print the list from file $1 (default: built afresh), recording it as shown.
show() {
  if [[ -n ${1:-} ]]; then
    cp "$1" "$state.list"
  else
    list >"$state.list"
  fi
  cat "$state.list"
}

# fzf actions that load $state.list with the cursor on session $1's line, or on
# its tab with id $2.
point_at() {
  local pos
  pos=$(awk -F'\t' -v s="$1" -v id="${2:-}" '
    $1 == s && (id == "" ? $2 == "" : $4 == id) { print NR; exit }
  ' "$state.list")
  echo "reload-sync(cat '$state.list')+pos(${pos:-1})"
}

reload_at() {
  list >"$state.list"
  point_at "$@"
}

# Move the line under the cursor down or up ($4): a tab ($2, with id $3) within
# its session, which wraps around at the ends, or a session ($1) in the list.
# fzf tracks the line through the reload (lines are identified by session and
# tab id, see --id-nth), so the cursor moves with it in the same frame.
move() {
  local s=$1 tab=$2 id=$3 dir=$4
  if [[ -z $tab ]]; then
    move_session "$s" "$dir"
  else
    if [[ -n $id ]]; then
      zellij --session "$s" action move-tab --tab-id "$id" \
        "$([[ $dir == down ]] && echo right || echo left)" || true
    fi
    list >"$state.list"
  fi
  echo "track-current+reload-sync(cat '$state.list')"
}

# Swap session $1's block of lines in $state.list with its neighbour's, number
# the first ten lines again, and save the new order.
move_session() {
  local tmp
  mkdir -p "${order%/*}"
  tmp=$(mktemp "$state.XXXXXX")
  awk -F'\t' -v OFS='\t' -v target="$1" -v dir="$2" -v order="$order" '
    {
      sub(/^\033\[2m\([0-9]\)\033\[0m /, "", $3)
      line[NR] = $0
      owner[NR] = $1
      if ($2 == "") names[++n] = $1
    }
    END {
      for (i = 1; i <= n; i++) if (names[i] == target) k = i
      j = dir == "down" ? k + 1 : k - 1
      if (k && j >= 1 && j <= n) {
        t = names[k]; names[k] = names[j]; names[j] = t
      }
      printf "" >order
      for (i = 1; i <= n; i++) {
        print names[i] >order
        for (r = 1; r <= NR; r++) {
          if (owner[r] != names[i]) continue
          m = split(line[r], f, "\t")
          if (++out <= 10) f[3] = "\033[2m(" out - 1 ")\033[0m " f[3]
          l = f[1]
          for (c = 2; c <= m; c++) l = l "\t" f[c]
          print l
        }
      }
    }
  ' "$state.list" >"$tmp"
  mv "$tmp" "$state.list"
}

# Keys that act in navigation mode and are released to the query in search mode.
nav='j,k,J,K,h,l,g,G,x,q,/,0,1,2,3,4,5,6,7,8,9'

# Digit N picks line (N), if the list is that long.
digit() {
  if ((${FZF_TOTAL_COUNT:-0} > $1)); then
    echo "pos($(($1 + 1)))+accept"
  fi
}

# Killing the attached session would detach the client, so move it to the first
# other session first, as tmux does. switch-session returns before the client has
# moved, hence the pause.
kill_session() {
  local other
  if [[ $1 == "$current" ]]; then
    other=$(sessions | grep -vxF "$1" | head -n1 || true)
    if [[ -n $other ]]; then
      zellij action switch-session "$other"
      sleep 0.5
    fi
  fi
  zellij kill-session "$1" || true
  rm -f "$roots/$1"
  # Other sessions' pickers would open on a list still showing it: drop their
  # cached lists (the caller refreshes its own)
  find "${cache%/*}" -maxdepth 1 -name 'list.*' ! -path "$cache" -delete 2>/dev/null || true
}

# esc leaves search mode, or quits from navigation mode.
esc() {
  if [[ ${FZF_INPUT_STATE:-} == hidden ]]; then
    echo abort
  else
    echo "clear-query+hide-input+search()+rebind($nav)+reload(bash '$self' show)"
  fi
}

# fzf transform actions; $1 is the session, $2 the tab ('' on a session line).
expand() {
  [[ -z ${2:-} ]] || return 0
  grep -qxF "$1" "$state" || echo "$1" >>"$state"
  reload_at "$1"
}

collapse() {
  grep -qxF "$1" "$state" || return 0
  grep -vxF "$1" "$state" >"$state.tmp" || true
  mv "$state.tmp" "$state"
  reload_at "$1"
}

# The branch for the status bar (plugins/bar), run in the focused pane's
# directory; it fails outside a repository.
branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Session named after directory $1 (default: the current one), created there if
# it doesn't exist. Inside zellij this switches to it rather than nesting a client.
here() {
  local dir name
  dir=$(realpath -e -- "${1:-.}" 2>/dev/null) && [[ -d $dir ]] || {
    echo "zellij-tree: not a directory: ${1:-.}" >&2
    return 1
  }
  cd -- "$dir"
  name=$(basename "$dir" | tr . -)
  if ! sessions | grep -qxF "$name"; then
    set_root "$name" "$dir"
    if [[ -z ${ZELLIJ:-} ]]; then
      exec zellij attach --create "$name"
    fi
    # Keep the hook's marker out of the new server, or its shells skip the root
    env -u ZELLIJ_ROOTED zellij attach --create-background "$name"
  elif [[ -z ${ZELLIJ:-} ]]; then
    exec zellij attach "$name"
  fi
  zellij action switch-session "$name"
}

# Bound to C-s Enter, which runs this in a small floating pane in the focused
# pane's directory.
root() {
  set_root "$current" "$PWD"
  printf '\n  Session root: %s\n' "$PWD"
  sleep 1
}

pick() {
  local sel s tab start search
  ZELLIJ_TREE_STATE=$(mktemp -t zellij-tree.XXXXXX)
  export ZELLIJ_TREE_STATE
  state=$ZELLIJ_TREE_STATE
  trap 'rm -f "$state" "$state".*' EXIT

  # Building the list takes a round trip to every session, so the picker opens
  # on the last run's list and swaps in a fresh one when it is ready. Listing
  # the sessions alone is cheap, so a cache whose sessions are no longer the
  # live ones (made, killed or exited since) is rebuilt before opening, or the
  # swap would add and drop sessions under the cursor.
  local refresh=""
  if [[ -s $cache && $(awk -F'\t' '$2 == "" { print $1 }' "$cache") == "$(sessions)" ]]; then
    cp "$cache" "$state.list"
    refresh="+reload-sync(bash '$self' refresh)"
  else
    refresh >/dev/null
  fi
  start=$(cut -f1,2 "$state.list" | grep -nxF "$current"$'\t' | cut -d: -f1 || true)

  # Key hints: bold green keys, labels in fzf's footer colour
  local footer="" hint
  for hint in "J/K reorder" "/ search" "x kill" "q quit"; do
    footer+="${footer:+  }"$'\033[1;32m'"${hint%% *}"$'\033[0m'" ${hint#* }"
  done

  search="untrack-current+show-input+unbind($nav)+reload-sync(bash '$self' list --all)"
  local d digits=()
  for d in {0..9}; do
    digits+=("--bind=$d:transform:bash '$self' digit $d")
  done
  sel=$(
    fzf <"$state.list" \
      --ansi --no-sort --layout=reverse --no-input --cycle \
      --delimiter='\t' --with-nth=3 --id-nth=1,4 \
      --prompt='/' \
      --footer="$footer" --footer-border=none \
      --preview="bash '$self' preview {1} {2}" \
      --preview-window='right,60%,follow' \
      --bind="load:pos(${start:-1})+unbind(load)$refresh" \
      --bind='j:down,k:up,g:first,G:last,q:abort' \
      --bind="l:transform(bash '$self' expand {1} {2})" \
      --bind="h:transform(bash '$self' collapse {1} {2})" \
      --bind="J:transform(bash '$self' move {1} {2} {4} down)" \
      --bind="K:transform(bash '$self' move {1} {2} {4} up)" \
      --bind="x:execute-silent(bash '$self' kill {1})+reload(bash '$self' refresh)" \
      "${digits[@]}" \
      --bind="/:$search" \
      --bind="esc:transform:bash '$self' esc"
  ) || exit 0

  s=$(cut -f1 <<<"$sel")
  tab=$(cut -f2 <<<"$sel")

  if [[ $s == "$current" ]]; then
    [[ -n $tab ]] && zellij action go-to-tab $((tab + 1))
  elif [[ -n $tab ]]; then
    zellij action switch-session "$s" --tab-position "$tab"
  else
    zellij action switch-session "$s"
  fi
}

case "${1:-}" in
list) list "${2:-}" ;;
refresh) refresh ;;
show) show ;;
preview) preview "$2" "${3:-}" ;;
expand) expand "$2" "${3:-}" ;;
collapse) collapse "$2" "${3:-}" ;;
esc) esc ;;
branch) branch ;;
here) here "${2:-}" ;;
root) root ;;
digit) digit "$2" ;;
kill) kill_session "$2" ;;
move) move "$2" "${3:-}" "${4:-}" "$5" ;;
*) pick ;;
esac
