{
  description = "Tool to package repositories for AI analysis and copy to clipboard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = import ./flake-module.nix;

      flake = {
        overlays.default = final: _prev: {
          inherit (inputs.self.packages.${final.system}) repomix-to-clipboard;
        };
      };
    };
}
