{ config, ... }:

let
  inherit (config) style;
in
{
  flake.modules.nixos.fonts =
    { pkgs, ... }:

    {
      fonts = {
        packages = [
          pkgs.font-awesome
        ]
        ++ style.font.packages pkgs
        ++ (with pkgs; [
          # Additional fonts for PDF compatibility
          liberation_ttf
          dejavu_fonts
          noto-fonts
          noto-fonts-color-emoji
        ]);

        fontconfig = {
          enable = true;
          defaultFonts = {
            serif = [
              "Liberation Serif"
              "DejaVu Serif"
            ];
            sansSerif = [
              "Liberation Sans"
              "DejaVu Sans"
            ];
            monospace = [
              style.font.mono
              style.font.monoFallback
            ];
          };
        };
      };
    };
}
