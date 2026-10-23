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
      xdg.configFile."nvim".source = link-dotfile ./nvim;

      home.packages = [ pkgs.lua-language-server ];

      programs.neovim = {
        enable = true;
        withNodeJs = true;
        withPython3 = false;
        withRuby = false;
        # init.lua is the hot-reloaded dotfile above; pass HM's provider settings through the wrapper instead
        sideloadInitLua = true;
      };
    };
}
