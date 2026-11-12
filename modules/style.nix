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

    # One per variant; darkman swaps between them at runtime [ref:active-wallpaper].
    wallpaper = {
      dark = ./desktop/wallpapers/dark-space.jpg;
      light = ./desktop/wallpapers/02108_navajoland_1920x1080.jpg;
    };
  };
}
