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
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.home-manager ];

      home.stateVersion = "21.11";

      programs.password-store = {
        enable = true;
        settings.PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
      };

      # Default applications for file types; features add their own entries
      xdg.mimeApps.enable = true;
    };
}
