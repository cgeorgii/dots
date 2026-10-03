{ config, ... }:

let
  inherit (config) style;
in
{
  # GTK, Qt and cursor defaults; the runtime palette comes from theme.nix.
  flake.modules.homeManager.theme =
    { pkgs, ... }:
    {
      # Session variables (XDG_CURRENT_DESKTOP set by compositor)
      home.sessionVariables = {
        XCURSOR_THEME = style.cursor.name;
        XCURSOR_SIZE = toString style.cursor.size;
      };

      gtk = {
        enable = true;
        # darkman swaps between the dark and light variants at runtime via the
        # gtk-theme gsetting. This is only the boot default.
        theme = {
          name = style.gtk.dark;
          package = style.gtk.package pkgs;
        };
        iconTheme = {
          name = style.icons.name;
          package = style.icons.package pkgs;
        };
        cursorTheme = {
          name = style.cursor.name;
          package = style.cursor.package pkgs;
        };
        # No static prefer-dark hint: the light/dark choice is driven at runtime
        # by darkman through the color-scheme gsetting and the gtk-theme name.
      };

      # KDE platform theme so Qt apps (Dolphin especially) colour themselves
      # from ~/.config/kdeglobals, which tinty-render regenerates from the
      # active base16 palette. Breeze style + kde platform theme make every
      # widget follow that scheme, matching the rest of the base16 system.
      qt = {
        enable = true;
        platformTheme.name = "kde";
        style.name = "breeze";
      };
    };
}
