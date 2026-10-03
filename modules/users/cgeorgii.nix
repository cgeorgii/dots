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
}
