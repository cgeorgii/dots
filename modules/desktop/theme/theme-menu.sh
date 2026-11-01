#!/usr/bin/env bash
# theme-menu — fzf picker over every tinty scheme, and the place to triage them.
#
#   j/k     move down/up (g/G first/last, ctrl-d/ctrl-u half a page)
#   /       search; enter keeps the query, esc clears it, both back to the list
#   enter   apply the highlighted scheme in place (the list stays open, and the
#           terminal re-themes under fzf, so you can browse live)
#   space   cycle its mark: unmarked -> keep -> skip -> unmarked
#   tab     cycle the view: kept -> unreviewed -> all
#   ctrl-t  cycle the variant: both -> dark -> light
#   q, esc  close
#
# Marks [ref:scheme-marks] live in $THEME_MARKS (one "keep|skip <id>" per
# line); the kept schemes are darkman's daily rotation. $THEME_VARIANTS lists
# "<id> <dark|light>" for every scheme. Both, and the tinty paths, come from
# the Nix wrapper.
set -u

: "${THEME_MARKS:?} ${THEME_VARIANTS:?} ${TINTY_CONFIG:?} ${TINTY_DATA:?}"
self="bash $(printf '%q' "$0")"
views=(kept unreviewed all)
variants=(both dark light)

# The filters of this session, one file each in $THEME_MENU_STATE
get() { cat "$THEME_MENU_STATE/$1"; }

# Advance filter $1 to the value after its current one among the rest. Rows
# marked under the old filters stop being pinned.
cycle() {
  : >"$THEME_MENU_STATE/marked"
  name="$1"
  shift
  cur="$(get "$name")"
  vals=("$@")
  for i in "${!vals[@]}"; do
    [ "${vals[$i]}" = "$cur" ] && echo "${vals[$(((i + 1) % ${#vals[@]}))]}" >"$THEME_MENU_STATE/$name"
  done
}

# Rows are "<mark>\t<variant>\t<id>" for the current filters. Rows marked
# since the filters last changed stay listed even when their new mark no
# longer matches the view, so TAB shows the mark instead of hiding the row.
list() {
  awk -v view="$(get view)" -v variant="$(get variant)" '
    FILENAME == ARGV[1] { pinned[$1] = 1; next }
    FILENAME == ARGV[2] { if ($1 == "keep" || $1 == "skip") m[$2] = $1; next }
    {
      s = ($1 in m) ? m[$1] : ""
      if (view == "kept" && s != "keep" && !($1 in pinned)) next
      if (view == "unreviewed" && s != "" && !($1 in pinned)) next
      if (variant != "both" && $2 != variant) next
      printf "%s\t%s\t%s\n", (s == "keep" ? "✓" : s == "skip" ? "✗" : " "), $2, $1
    }
  ' "$THEME_MENU_STATE/marked" "$THEME_MARKS" "$THEME_VARIANTS"
}

mark() {
  echo "$1" >>"$THEME_MENU_STATE/marked"
  tmp="$(mktemp "$THEME_MARKS.XXXXXX")"
  # Comments stay on top; marks are kept sorted by id for readable diffs.
  {
    grep '^#' "$THEME_MARKS"
    awk -v id="$1" '
      /^#/ || NF == 0 { next }
      $2 == id { found = 1; if ($1 == "keep") print "skip", id; next }
      { print }
      END { if (!found) print "keep", id }
    ' "$THEME_MARKS" | LC_ALL=C sort -k2
  } >"$tmp" && mv "$tmp" "$THEME_MARKS"
}

header() {
  name="$(tinty current name "${tinty_args[@]}" 2>/dev/null)"
  id="$(tinty current "${tinty_args[@]}" 2>/dev/null)"
  printf "current: %s (%s)\n" "${name:-?}" "${id:-?}"
  printf "view: %s   variant: %s\n" "$(get view)" "$(get variant)"
  printf "j/k g/G ^d/^u: move   /: search   enter: apply   space: keep/skip\n"
  printf "tab: view   ctrl-t: variant   q/esc: close"
}

# Vim-style modes: the list opens with the input hidden so letters can be
# motions; `/` shows it and frees those letters for typing. In search, enter
# keeps the query and esc clears it, both back to the list. These print the
# action for fzf's transform, which sets $FZF_INPUT_STATE.
motions="j,k,g,G,q,/,space"
searching() { [ "${FZF_INPUT_STATE:-}" = enabled ]; }
on_enter() {
  if searching; then echo "hide-input+rebind($motions)"; else echo "execute-silent($self apply {3})+transform-header($self header)"; fi
}
on_esc() {
  if searching; then echo "hide-input+rebind($motions)"; else echo abort; fi
}

tinty_args=(--config "$TINTY_CONFIG" --data-dir "$TINTY_DATA")

case "${1:-}" in
  list) list; exit ;;
  mark) mark "$2"; exit ;;
  apply) tinty apply "$2" "${tinty_args[@]}"; exit ;;
  next-view) cycle view "${views[@]}"; exit ;;
  next-variant) cycle variant "${variants[@]}"; exit ;;
  header) header; exit ;;
  on-enter) on_enter; exit ;;
  on-esc) on_esc; exit ;;
esac

THEME_MENU_STATE="$(mktemp -d)"
export THEME_MENU_STATE
trap 'rm -rf "$THEME_MENU_STATE"' EXIT
echo kept >"$THEME_MENU_STATE/view"
echo both >"$THEME_MENU_STATE/variant"
: >"$THEME_MENU_STATE/marked"

rows="$(list)"
cur="$(tinty current "${tinty_args[@]}" 2>/dev/null)"
idx="$(printf '%s\n' "$rows" | cut -f3 | grep -nxF -- "$cur" | cut -d: -f1)"

# Changing a filter reloads the list and redraws the header that shows it
refilter="+reload($self list)+transform-header($self header)"
args=(
  --layout=reverse
  --delimiter '\t'
  --nth 2,3
  --prompt '/'
  --header "$(header)"
  --no-input
  --bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up,q:abort"
  --bind "/:show-input+unbind($motions)"
  --bind "enter:transform($self on-enter)"
  --bind "esc:clear-query+transform($self on-esc)"
  --bind "space:execute-silent($self mark {3})+reload($self list)"
  --bind "tab:execute-silent($self next-view)$refilter"
  --bind "ctrl-t:execute-silent($self next-variant)$refilter"
)
[ -n "$idx" ] && args+=(--bind "load:pos($idx)+unbind(load)")
printf '%s\n' "$rows" | fzf "${args[@]}" || true
