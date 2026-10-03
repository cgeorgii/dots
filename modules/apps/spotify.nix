{ inputs, ... }:

{
  flake.modules.homeManager.spotify =
    { pkgs, ... }:
    let
      spotify-pkgs = import inputs.nixpkgs-for-spotify {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "spotify"
          ];
      };
    in
    {
      home.packages = [ spotify-pkgs.spotify ];
    };
}
