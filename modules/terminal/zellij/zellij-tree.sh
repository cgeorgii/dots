#!/usr/bin/env bash
# tmux choose-tree style session/tab picker for zellij, built on fzf.
#
# Starts in navigation mode (j/k move, l/h expand/collapse, enter switches);
# `/` shows the query box and expands every session, esc goes back.
#
#   zellij-tree                  run the picker (usually inside a floating pane)
#   zellij-tree list [--all]     print the tree, tab-separated: session, tab, label
#   zellij-tree preview S [T]    print the focused pane of session S, tab T
#   zellij-tree expand|collapse  fzf actions for the line under the cursor
#   zellij-tree badge            print session@branch for the status bar
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

set_root() {
  mkdir -p "$roots"
  printf '%s\n' "$2" >"$roots/$1"
}

sessions() {
  # Live sessions only: exited ones can't be listed or previewed.
  zellij list-sessions --no-formatting 2>/dev/null |
    grep -v 'EXITED' |
    awk '{ print $1 }'
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
        "\($s)\t\(.value.position)\t    \(if .key == $last then "└─" else "├─" end) \(.value.position + 1): \(.value.name)\(if .value.active then " \u001b[33m*\u001b[0m" else "" end)"
      else empty end)
    ' "$tmp/$i"
  done
  rm -rf "$tmp"
}

preview() {
  local s=$1 tab=${2:-} panes pane
  panes=$(zellij --session "$s" action list-panes --json --all 2>/dev/null) || {
    echo "session $s is not reachable"
    return
  }
  if [[ -z $tab ]]; then
    tab=$(zellij --session "$s" action list-tabs --json 2>/dev/null |
      jq -r 'map(select(.active)) | first | .position // 0')
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

# Rebuild the list and print the fzf actions that load it with the cursor on
# session $1's line.
reload_at() {
  local cache="$state.list" pos
  list >"$cache"
  pos=$(cut -f1,2 "$cache" | grep -nxF "$1"$'\t' | cut -d: -f1 || true)
  echo "reload-sync(cat '$cache')+pos(${pos:-1})"
}

# Keys that act in navigation mode and are released to the query in search mode.
nav='j,k,h,l,g,G,x,q,/,0,1,2,3,4,5,6,7,8,9'

# Digit N picks line (N), if the list is that long.
digit() {
  if ((${FZF_TOTAL_COUNT:-0} > $1)); then
    echo "pos($(($1 + 1)))+accept"
  fi
}

kill_session() {
  zellij kill-session "$1" || true
  rm -f "$roots/$1"
}

# esc leaves search mode, or quits from navigation mode.
esc() {
  if [[ ${FZF_INPUT_STATE:-} == hidden ]]; then
    echo abort
  else
    echo "clear-query+hide-input+search()+rebind($nav)+reload(bash '$self' list)"
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

# The zjstatus session block: run with the focused pane's directory as cwd, from
# the zellij server, whose environment names the session.
badge() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  printf '%s%s' "$current" "${branch:+@$branch}"
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
  trap 'rm -f "$state" "$state.list" "$state.tmp"' EXIT

  # Built once, both for fzf and to start the cursor on the attached session
  list >"$state.list"
  start=$(cut -f1,2 "$state.list" | grep -nxF "$current"$'\t' | cut -d: -f1 || true)

  # Key hints: bold green keys, labels in fzf's footer colour
  local footer="" hint
  for hint in "/ search" "x kill" "q quit"; do
    footer+="${footer:+  }"$'\033[1;32m'"${hint%% *}"$'\033[0m'" ${hint#* }"
  done

  search="show-input+unbind($nav)+reload-sync(bash '$self' list --all)"
  local d digits=()
  for d in {0..9}; do
    digits+=("--bind=$d:transform:bash '$self' digit $d")
  done
  sel=$(
    fzf <"$state.list" \
      --ansi --no-sort --layout=reverse --sync --no-input \
      --delimiter='\t' --with-nth=3 \
      --prompt='/' \
      --footer="$footer" --footer-border=none \
      --preview="bash '$self' preview {1} {2}" \
      --preview-window='right,60%,follow' \
      --bind="start:pos(${start:-1})" \
      --bind='j:down,k:up,g:first,G:last,q:abort' \
      --bind="l:transform(bash '$self' expand {1} {2})" \
      --bind="h:transform(bash '$self' collapse {1} {2})" \
      --bind="x:execute-silent(bash '$self' kill {1})+reload(bash '$self' list)" \
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
preview) preview "$2" "${3:-}" ;;
expand) expand "$2" "${3:-}" ;;
collapse) collapse "$2" "${3:-}" ;;
esc) esc ;;
badge) badge ;;
here) here "${2:-}" ;;
root) root ;;
digit) digit "$2" ;;
kill) kill_session "$2" ;;
*) pick ;;
esac
