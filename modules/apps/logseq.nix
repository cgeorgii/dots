{ inputs, ... }:

{
  flake.modules.nixos.logseq =
    { pkgs, ... }:

    let
      logseq-pkgs = import inputs.nixpkgs-for-logseq {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "logseq"
          ];
      };
    in
    {
      environment.systemPackages = [
        logseq-pkgs.logseq
      ];
    };
}
