{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term

      # Additional fonts for PDF compatibility
      liberation_ttf
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
    ];

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
          "IosevkaTerm Nerd Font Mono"
          "Iosevka Nerd Font Mono"
        ];
      };
    };
  };
}
