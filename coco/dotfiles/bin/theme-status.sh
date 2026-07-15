#!/usr/bin/env bash
# waybar custom module for the current theme.
#   (no arg)  -> print JSON {text,tooltip,class} for the module
#   toggle    -> flip light/dark via darkman (bound to on-click)
#   menu      -> open the theme picker in a terminal (bound to on-click-right)
# A plain dotfile so it hot-reloads; it sets its own PATH because waybar's
# systemd environment is lean.
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
set -u

case "${1:-}" in
  toggle) exec darkman toggle ;;
  menu) exec kitty -e theme-menu ;;
esac

mode="$(darkman get 2>/dev/null || echo dark)"
name="$(tinty current name 2>/dev/null || echo '?')"
id="$(tinty current 2>/dev/null || echo '?')"
name="${name//\"/}" # keep the JSON well-formed

# Font Awesome sun (light) / moon (dark); \u escapes so the glyphs survive edits.
if [ "$mode" = "light" ]; then icon=$''; else icon=$''; fi
printf '{"text":"<span size='\''xx-large'\''>%s</span>","tooltip":"%s\\n%s (%s)","class":"%s"}\n' "$icon" "$name" "$id" "$mode" "$mode"
