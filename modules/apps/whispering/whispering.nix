{ self, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.whispering = pkgs.callPackage ./_package.nix { };
    };

  flake.modules.homeManager.whispering =
    { pkgs, ... }:
    {
      home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.whispering ];
    };
}
