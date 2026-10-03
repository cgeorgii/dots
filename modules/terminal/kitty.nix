{ self, inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.kitty = inputs.wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;
        themeFile = "gruvbox-dark"; # boot default; overridden by the include below
        # Appended last so it wins over themeFile. darkman repoints
        # theme-active.conf at the dark/light theme and sends SIGUSR1 to reload.
        # Absolute, since the generated kitty.conf lives in the store.
        extraConfig = "include \${HOME}/.config/kitty/theme-active.conf";
        font = {
          name = "IosevkaTerm Nerd Font Mono";
          size = 14;
        };
        settings = {
          # Match alacritty's minimal look
          window_padding_width = 4;
          hide_window_decorations = true;
          # Cursor
          cursor_shape = "block";
          cursor_blink_interval = 0;
          # Scrollback
          scrollback_lines = 10000;
          # No audio bell
          enable_audio_bell = false;
          # Environment
          env = "EDITOR=nvim";
        };
      };
    };

  flake.modules.homeManager.kitty =
    { pkgs, ... }:
    {
      home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.kitty ];
    };
}
