{
  flake.modules.nixos.cgeorgii =
    { pkgs, ... }:
    {
      users.users.cgeorgii = {
        isNormalUser = true;
        shell = pkgs.zsh;
        home = "/home/cgeorgii";
        extraGroups = [
          "audio"
          "wheel"
          "networkmanager"
        ];
      };
    };

  flake.modules.homeManager.cgeorgii =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.home-manager ];

      home.stateVersion = "21.11";

      programs.password-store.enable = true;

      # Default applications for file types; features add their own entries
      xdg.mimeApps.enable = true;
    };
}
