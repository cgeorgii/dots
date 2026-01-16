{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Revert this after claude 2.0 is out on nixos-unstable
    # nixpkgs-for-claude.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-claude.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-signal.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-spotify.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      systems = [ "x86_64-linux" ];

      perSystem =
        {
          system,
          config,
          final,
          ...
        }:
        {
          checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              deadnix.enable = true;
            };
          };

          devShells.default = final.mkShell {
            inherit (config.checks.pre-commit-check) shellHook;
            name = "coco-dev";
            packages = [
              final.nil
              final.git-bug
            ];
          };

          overlayAttrs = {
            whispering = final.callPackage ./coco/pkgs/whispering.nix { };
          };

        };

      flake = {
        nixosModules.default.nixpkgs.overlays = [ inputs.self.overlays.default ];
        nixosConfigurations = {
          coco = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              # Apply our overlay module
              inputs.self.nixosModules.default

              # Consolidated coco configuration
              ./coco
            ];
          };
        };
      };
    };
}
