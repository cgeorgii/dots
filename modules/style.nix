{ lib, ... }:

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
      # fuzzel's prompt and list, which read better larger
      launcherSize = 18;
    };

    cursor = {
      name = "Adwaita";
      size = 24;
      package = pkgs: pkgs.adwaita-icon-theme;
    };

    icons = {
      name = "Mint-Y-Sand";
      package = pkgs: pkgs.mint-y-icons;
    };

    # Both variants ship in one package; darkman swaps between them at runtime.
    gtk = {
      dark = "Gruvbox-Dark";
      light = "Gruvbox-Light";
      package = pkgs: pkgs.gruvbox-gtk-theme;
    };

    wallpaper = ./desktop/wallpapers/02108_navajoland_1920x1080.jpg;
  };
}
