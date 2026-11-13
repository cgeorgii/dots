{ lib, ... }:

# [tag:shared-style] The one place for fonts, cursor, icons, GTK theme and
# wallpaper; hot-reloaded configs get generated files that include it.
{
  options.style = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    description = ''
      The shared look: fonts, sizes, cursor, icons, GTK theme and wallpaper.
      Features read it as `config.style` from the flake scope. Packages are
      functions of `pkgs`, so a name and the package that provides it are
      always set together.
    '';
  };

  config.style = {
    font = {
      mono = "IosevkaTerm Nerd Font Mono";
      monoFallback = "Iosevka Nerd Font Mono";
      packages = pkgs: [
        pkgs.nerd-fonts.iosevka
        pkgs.nerd-fonts.iosevka-term
      ];
      size = 14;
      uiSize = 11;
    };

    cursor = {
      name = "Adwaita";
      size = 24;
      package = pkgs: pkgs.adwaita-icon-theme;
    };

    icons = {
      name = "Papirus";
      package = pkgs: pkgs.papirus-icon-theme;
    };

    # Both variants ship in one package; darkman swaps between them at runtime.
    gtk = {
      dark = "Gruvbox-Dark";
      light = "Gruvbox-Light";
      # The GTK 3 stylesheets carry a GTK 4-only `border-spacing` declaration
      # that every GTK 3 app reports as a theme parsing error on startup.
      package =
        pkgs:
        pkgs.gruvbox-gtk-theme.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            find $out/share/themes -path '*/gtk-3.0/*.css' -type f \
              -exec sed -i '/^\s*border-spacing:/d' {} +
          '';
        });
    };

    # fzf drawn only from the terminal's ANSI palette, which tinty-render maps
    # from the active scheme [file:modules/desktop/theme/tinty-render.sh]
    # (18-20 are base01, base02, base04), so pickers follow light and dark.
    # fzf's own defaults are fixed 256-colour greys that only suit dark.
    fzf = rec {
      colors = {
        fg = "-1";
        bg = "-1";
        "fg+" = "-1";
        "bg+" = "19";
        gutter = "-1";
        hl = "4";
        "hl+" = "4";
        header = "20";
        footer = "20";
        info = "20";
        prompt = "4";
        pointer = "1";
        marker = "2";
        spinner = "6";
        label = "4";
        border = "8";
        separator = "8";
        scrollbar = "8";
      };
      # For pickers launched outside a login shell, which lack FZF_DEFAULT_OPTS
      flag = "--color=" + lib.concatStringsSep "," (lib.mapAttrsToList (k: v: "${k}:${v}") colors);
    };

    # One per variant; darkman swaps between them at runtime [ref:active-wallpaper].
    wallpaper = {
      dark = ./desktop/wallpapers/dark-space.jpg;
      light = ./desktop/wallpapers/02108_navajoland_1920x1080.jpg;
    };
  };
}
