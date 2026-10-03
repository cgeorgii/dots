{
  flake.modules.nixos.neovim =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gcc # Required for neovim-treesitter
      ];

      environment.variables.EDITOR = "nvim";
    };

  flake.modules.homeManager.neovim =
    { pkgs, link-dotfile, ... }:
    {
      # Link the entire nvim directory structure
      xdg.configFile."nvim".source = link-dotfile "nvim";

      home.packages = [ pkgs.lua-language-server ];

      programs.neovim = {
        enable = true;
        withNodeJs = true;
      };
    };
}
