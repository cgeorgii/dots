#!/usr/bin/env bash
# accent-menu — fzf picker for the shared accent [ref:shared-accent]: which
# palette slot colours focus and chrome (niri's focus ring, the bar border,
# zellij's focused pane...), whatever scheme is active.
#
#   j/k     move down/up (g/G first/last)
#   enter   use the highlighted slot; everything re-themes live and the list
#           stays open, so you can compare
#   q, esc  close
#
# The slot is kept in $THEME_ACCENT, a hot-reloaded file in the checkout, so
# the choice holds across schemes. The swatches show the current scheme's
# colours; a base24 bright slot on a base16 scheme falls back to its normal
# slot, as tinty-render does. The paths come from the Nix wrapper.
set -u

: "${THEME_ACCENT:?} ${TINTY_CONFIG:?} ${TINTY_DATA:?}"
self="bash $(printf '%q' "$0")"
tinty_args=(--config "$TINTY_CONFIG" --data-dir "$TINTY_DATA")

slots=(08 09 0A 0B 0C 0D 0E 0F 12 13 14 15 16 17)
declare -A role=(
  [08]="red" [09]="orange" [0A]="yellow" [0B]="green"
  [0C]="cyan" [0D]="blue" [0E]="magenta" [0F]="brown"
  [12]="bright red" [13]="bright yellow" [14]="bright green"
  [15]="bright cyan" [16]="bright blue" [17]="bright magenta"
)
declare -A normal=([12]=08 [13]=0A [14]=0B [15]=0C [16]=0D [17]=0E)

current_slot() { tr -d '[:space:]' <"$THEME_ACCENT" 2>/dev/null; }

# "<slot> <rrggbb>" for every slot of the active scheme's YAML
palette() {
  id="$(tinty current "${tinty_args[@]}" 2>/dev/null)"
  for f in "$TINTY_DATA/scheme-repos/schemes/${id%%-*}/${id#*-}".y*ml; do
    sed -n 's/^ *base\([0-9A-Fa-f]\{2\}\): *"\{0,1\}#\{0,1\}\([0-9A-Fa-f]\{6\}\).*/\1 \2/p' "$f"
  done
}

# Rows are "<slot>\t<swatch>  <role>  #hex", the current accent marked
list() {
  declare -A hex
  while read -r k v; do hex[$k]="$v"; done < <(palette)
  cur="$(current_slot)"
  for s in "${slots[@]}"; do
    h="${hex[$s]:-}" note=""
    if [ -z "$h" ] && [ -n "${normal[$s]:-}" ]; then
      h="${hex[${normal[$s]}]:-}"
      note=" (= base${normal[$s]}, no base24 brights)"
    fi
    if [ -n "$h" ]; then
      swatch="$(printf '\033[48;2;%d;%d;%dm      \033[0m' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}")"
    else
      swatch="  ??  " h="??????"
    fi
    printf '%s\t%s %s  base%s  %-14s #%s%s\n' \
      "$s" "$([ "$s" = "$cur" ] && echo '●' || echo ' ')" "$swatch" "$s" "${role[$s]}" "$h" "$note"
  done
}

header() {
  name="$(tinty current name "${tinty_args[@]}" 2>/dev/null)"
  printf "scheme: %s   accent: base%s\n" "${name:-?}" "$(current_slot)"
  printf "j/k g/G: move   enter: use as accent   q/esc: close\n"
  printf "(role names are base16 conventions; schemes may differ)"
}

# Write the slot, then re-apply the current scheme so tinty-render repaints
apply() {
  printf '%s\n' "$1" >"$THEME_ACCENT"
  tinty apply "$(tinty current "${tinty_args[@]}")" "${tinty_args[@]}" >/dev/null 2>&1
}

case "${1:-}" in
  list) list; exit ;;
  header) header; exit ;;
  apply) apply "$2"; exit ;;
esac

rows="$(list)"
idx="$(printf '%s\n' "$rows" | cut -f1 | grep -nxF -- "$(current_slot)" | cut -d: -f1)"
args=(
  --ansi
  --layout=reverse
  --delimiter '\t'
  --with-nth 2
  --no-input
  --header "$(header)"
  --bind "j:down,k:up,g:first,G:last,q:abort"
  --bind "enter:execute-silent($self apply {1})+reload($self list)+transform-header($self header)"
)
[ -n "$idx" ] && args+=(--bind "load:pos($idx)+unbind(load)")
printf '%s\n' "$rows" | fzf "${args[@]}" || true
