{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/dots/coco/dotfiles";

  # Single source of truth: the canonical base16 gruvbox palettes from
  # nix-colors. Every generated consumer below derives from these, so the theme
  # is defined once. base16's role system means one token -> base0X mapping
  # produces correct contrast in both the dark and light schemes automatically.
  palettes = {
    dark = inputs.nix-colors.colorSchemes.gruvbox-dark-medium.palette;
    light = inputs.nix-colors.colorSchemes.gruvbox-light-soft.palette;
  };

  # Kitty theme (base16 standard terminal mapping). p = a base16 palette.
  kittyTheme =
    p:
    pkgs.writeText "kitty-theme.conf" ''
      # Generated from nix-colors base16 gruvbox (see coco/home/theme.nix)
      background            #${p.base00}
      foreground            #${p.base05}
      selection_background  #${p.base05}
      selection_foreground  #${p.base00}
      cursor                #${p.base05}
      cursor_text_color     #${p.base00}
      url_color             #${p.base0D}

      color0  #${p.base00}
      color1  #${p.base08}
      color2  #${p.base0B}
      color3  #${p.base0A}
      color4  #${p.base0D}
      color5  #${p.base0E}
      color6  #${p.base0C}
      color7  #${p.base05}
      color8  #${p.base03}
      color9  #${p.base08}
      color10 #${p.base0B}
      color11 #${p.base0A}
      color12 #${p.base0D}
      color13 #${p.base0E}
      color14 #${p.base0C}
      color15 #${p.base07}
      color16 #${p.base09}
      color17 #${p.base0F}
      color18 #${p.base01}
      color19 #${p.base02}
      color20 #${p.base04}
      color21 #${p.base06}
    '';

  # Waybar colours consumed by style.css via @import "colors-active.css".
  waybarColors =
    p:
    pkgs.writeText "waybar-colors.css" ''
      /* Generated from nix-colors base16 gruvbox (see coco/home/theme.nix) */
      @define-color fg            #${p.base05};
      @define-color surface       #${p.base01};
      @define-color hover         #${p.base02};
      @define-color focused       #${p.base03};
      @define-color focused_hover #${p.base04};
      @define-color accent        #${p.base0A};
      @define-color warning       #${p.base09};
      @define-color critical      #${p.base08};
      @define-color critical_fg   #${p.base00};
      @define-color network       #${p.base0D};
    '';

  # Render a base16 palette as a lua table literal for nvim-base16's setup().
  base16Keys = [
    "base00"
    "base01"
    "base02"
    "base03"
    "base04"
    "base05"
    "base06"
    "base07"
    "base08"
    "base09"
    "base0A"
    "base0B"
    "base0C"
    "base0D"
    "base0E"
    "base0F"
  ];
  paletteToLua =
    p: "{ " + lib.concatMapStringsSep ", " (k: ''${k} = "#${p.${k}}"'') base16Keys + " }";

  # nvim consumes the exact same palette via base16-colorscheme.setup(), so its
  # background matches kitty/waybar/fuzzel and follows the variant automatically.
  nvimPalettes = pkgs.writeText "nvim-theme.lua" ''
    -- Generated from nix-colors base16 gruvbox (see coco/home/theme.nix)
    return {
      dark = ${paletteToLua palettes.dark},
      light = ${paletteToLua palettes.light},
    }
  '';

  # Full fuzzel config (static [main] + palette-derived [colors]). Selected at
  # launch by the fuzzel-themed wrapper. fuzzel colours are RRGGBBAA.
  fuzzelConfig =
    p:
    pkgs.writeText "fuzzel.ini" ''
      # Generated from nix-colors base16 gruvbox (see coco/home/theme.nix)
      [main]
      font=IosevkaTerm Nerd Font Mono:size=18
      dpi-aware=yes
      prompt=" > "
      icon-theme=Mint-Y-Sand
      terminal=kitty

      [colors]
      background=${p.base00}ff
      text=${p.base05}ff
      match=${p.base0A}ff
      selection=${p.base02}ff
      selection-text=${p.base07}ff
      selection-match=${p.base0A}ff
      border=${p.base0A}ff

      [border]
      width=2
      radius=0
    '';

  # dconf rather than gsettings: the darkman systemd service environment has no
  # gsettings schemas ("No schemas installed"), so `gsettings set` fails
  # silently. dconf writes the same database with no schema requirement, and
  # xdg-desktop-portal-gnome reads it back for org.freedesktop.appearance.
  dconf = "${pkgs.dconf}/bin/dconf";
  pkill = "${pkgs.procps}/bin/pkill";
  tmux = "${pkgs.tmux}/bin/tmux";

  # Body of the darkman hook for a given mode ("dark" | "light"). Both variants
  # are generated from this single source so the two stay in lockstep.
  switchScript =
    mode:
    let
      p = palettes.${mode};
      isDark = mode == "dark";
      colorScheme = if isDark then "prefer-dark" else "prefer-light";
      gtkTheme = if isDark then "Gruvbox-Dark" else "Gruvbox-Light";
    in
    ''
      # GTK / libadwaita / portal-aware apps: nemo, blueman, file-roller,
      # keepassxc, firefox (System theme), nvim (auto-dark-mode), and
      # web-content prefers-color-scheme.
      ${dconf} write /org/gnome/desktop/interface/color-scheme "'${colorScheme}'"
      ${dconf} write /org/gnome/desktop/interface/gtk-theme "'${gtkTheme}'"

      # Kitty: swap the included theme and live-reload every instance.
      ln -sf '${kittyTheme p}' "$HOME/.config/kitty/theme-active.conf"
      ${pkill} -USR1 kitty || true

      # Waybar: swap the imported colours and reload the stylesheet.
      ln -sf '${waybarColors p}' "$HOME/.config/waybar/colors-active.css"
      ${pkill} -USR2 waybar || true

      # delta (git pager): swap the included fragment. git re-reads config on
      # every invocation, so already-open shells pick this up with no reload.
      mkdir -p "$HOME/.config/delta"
      ln -sf '${dotfiles}/config/delta/delta-${mode}.gitconfig' "$HOME/.config/delta/theme-active.gitconfig"

      # tmux: re-theme every running server.
      if ${tmux} list-sessions >/dev/null 2>&1; then
        ${tmux} set -g @tmux-gruvbox '${mode}'
        ${tmux} run-shell "$HOME/.tmux/plugins/tmux-gruvbox/gruvbox-tpm.tmux" 2>/dev/null || true
      fi

      # nvim follows on its own via auto-dark-mode.nvim (polls color-scheme).
      # fuzzel picks its config per-launch through the fuzzel-themed wrapper.
      # niri's focus-ring uses accent colours that read well in both modes.
    '';

  # Fuzzel has no daemon and no include directive, so we pick the config file
  # at launch time based on the current darkman mode.
  fuzzel-themed = pkgs.writeShellScriptBin "fuzzel-themed" ''
    mode="$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo dark)"
    exec ${pkgs.fuzzel}/bin/fuzzel --config "$HOME/.config/fuzzel/fuzzel-$mode.ini" "$@"
  '';
in
{
  services.darkman = {
    enable = true;
    settings = {
      lat = 52.52;
      lng = 13.405;
      usegeoclue = false;
    };
    darkModeScripts.theme-switch = switchScript "dark";
    lightModeScripts.theme-switch = switchScript "light";
  };

  # Generated fuzzel variants (selected by the fuzzel-themed wrapper).
  xdg.configFile."fuzzel/fuzzel-dark.ini".source = fuzzelConfig palettes.dark;
  xdg.configFile."fuzzel/fuzzel-light.ini".source = fuzzelConfig palettes.light;

  # Shared palette for nvim (loaded by init.lua's auto-dark-mode config). Lives
  # outside ~/.config/nvim, which is a single out-of-store symlink.
  xdg.configFile."nvim-theme.lua".source = nvimPalettes;

  home.packages = [
    pkgs.darkman
    fuzzel-themed
  ];

  # Seed the runtime "active" files (pointing at the dark variants) so waybar
  # and kitty never start against a missing include before darkman's first run.
  # darkman replaces these symlinks with the correct mode at login.
  home.activation.seedThemeActive = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/delta"
    run ln -sf '${kittyTheme palettes.dark}' "$HOME/.config/kitty/theme-active.conf"
    run ln -sf '${waybarColors palettes.dark}' "$HOME/.config/waybar/colors-active.css"
    run ln -sf '${dotfiles}/config/delta/delta-dark.gitconfig' "$HOME/.config/delta/theme-active.gitconfig"
  '';
}
