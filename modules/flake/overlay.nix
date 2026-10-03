{ inputs, ... }:

{
  imports = [
    inputs.flake-parts.flakeModules.easyOverlay
  ];

  perSystem =
    { final, ... }:
    {
      overlayAttrs = {
        whispering = final.callPackage ../../pkgs/whispering.nix { };
      };
    };

  flake.nixosModules.default.nixpkgs.overlays = [ inputs.self.overlays.default ];
}
