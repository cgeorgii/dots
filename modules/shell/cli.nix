{
  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        autojump
        cachix
        devenv
        entr
        eza
        fd
        fzf
        gh
        glab
        hub
        imagemagick
        neofetch
        nixfmt
        ripgrep
        tree
      ];

      programs.jq = {
        enable = true;
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        defaultCommand = "fd --type f --hidden --exclude .git";
        fileWidgetCommand = "fd --type f --hidden --exclude .git";
        changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;

        config = {
          global = {
            hide_env_diff = true;
          };
        };
      };

      programs.autojump = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
