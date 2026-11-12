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
#   zellij-tree here             attach or switch to a session named after $PWD
set -euo pipefail

current="${ZELLIJ_SESSION_NAME:-}"
self=$(realpath "${BASH_SOURCE[0]}")
# Sessions whose tabs are shown, one per line; set up by `pick`.
state="${ZELLIJ_TREE_STATE:-/dev/null}"

sessions() {
  # Live sessions only: exited ones can't be listed or previewed.
  zellij list-sessions --no-formatting 2>/dev/null |
    grep -v 'EXITED' |
    awk '{ print $1 }'
}

list() {
  local all=${1:-} s tabs n mark arrow
  while read -r s; do
    tabs=$(zellij --session "$s" action list-tabs --json 2>/dev/null || echo '[]')
    n=$(jq length <<<"$tabs")
    mark=""
    [[ $s == "$current" ]] && mark=" \033[2m(attached)\033[0m"
    if [[ -n $all ]] || grep -qxF "$s" "$state" 2>/dev/null; then
      arrow="▾"
    else
      arrow="▸"
    fi
    printf "%s\t\t%s \033[1;34m%s\033[0m: %s tabs$mark\n" "$s" "$arrow" "$s" "$n"
    [[ $arrow == "▸" ]] && continue
    jq -r --arg s "$s" '
      sort_by(.position) | (length - 1) as $last | to_entries[] |
      "\($s)\t\(.value.position)\t    \(if .key == $last then "└─" else "├─" end) \(.value.position + 1): \(.value.name)\(if .value.active then " \u001b[33m*\u001b[0m" else "" end)"
    ' <<<"$tabs"
  done < <(sessions)
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
nav='j,k,h,l,g,G,x,q,/'

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

# Session named after the current directory, created there if it doesn't exist.
# Inside zellij this switches to it rather than nesting a client.
here() {
  local name
  name=$(basename "$PWD" | tr . -)
  if [[ -z ${ZELLIJ:-} ]]; then
    exec zellij attach --create "$name"
  fi
  if ! sessions | grep -qxF "$name"; then
    zellij attach --create-background "$name"
  fi
  zellij action switch-session "$name"
}

pick() {
  local sel s tab start search
  ZELLIJ_TREE_STATE=$(mktemp -t zellij-tree.XXXXXX)
  export ZELLIJ_TREE_STATE
  state=$ZELLIJ_TREE_STATE
  trap 'rm -f "$state" "$state.list" "$state.tmp"' EXIT

  start=$(list | cut -f1,2 | grep -nxF "$current"$'\t' | cut -d: -f1 || true)

  search="show-input+unbind($nav)+reload-sync(bash '$self' list --all)"
  sel=$(
    list | fzf \
      --ansi --no-sort --layout=reverse --sync --no-input \
      --delimiter='\t' --with-nth=3 \
      --prompt='/' \
      --header='j/k move · l/h expand/collapse · enter switch · x kill · / search · q quit' \
      --preview="bash '$self' preview {1} {2}" \
      --preview-window='right,60%,follow' \
      --bind="start:pos(${start:-1})" \
      --bind='j:down,k:up,g:first,G:last,q:abort' \
      --bind="l:transform(bash '$self' expand {1} {2})" \
      --bind="h:transform(bash '$self' collapse {1} {2})" \
      --bind="x:execute-silent(zellij kill-session {1})+reload(bash '$self' list)" \
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
here) here ;;
*) pick ;;
esac
