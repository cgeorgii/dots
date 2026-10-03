{ inputs, ... }:

{
  flake.modules.nixos.mullvad =
    { pkgs, ... }:

    let
      mullvad-pkgs = import inputs.nixpkgs-for-mullvad {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    {
      services.mullvad-vpn.enable = true;
      services.mullvad-vpn.package = mullvad-pkgs.mullvad-vpn;
    };
}
