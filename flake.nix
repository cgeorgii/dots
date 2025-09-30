{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Revert this after claude 2.0 is out on nixos-unstable
    # nixpkgs-for-claude.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-for-claude.url = "github:NixOS/nixpkgs/17aa85c";
    nixpkgs-for-signal.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      systems = [ "x86_64-linux" ];

      perSystem = { system, config, final, ... }: {
        checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            deadnix.enable = true;
          };
        };

        devShells.default = final.mkShell {
          inherit (config.checks.pre-commit-check) shellHook;
          packages = [
            final.nil
            final.git-bug
          ];
        };

        overlayAttrs = {
          # Add any other custom packages here
        };

      };

      flake = {
        # A common module to apply overlays
        nixosModules.default.nixpkgs.overlays = [ inputs.self.overlays.default ];
        nixosConfigurations = {
          coco = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [
              # Apply our overlay module
              inputs.self.nixosModules.default

              # Hardware config
              ./coco/hardware-configuration.nix
              inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
              # Common config
              ./common.nix
              # System-specific config
              ./coco/configuration.nix
              # Home-manager
              inputs.home-manager.nixosModules.home-manager
              ./home/cgeorgii.nix
            ];
          };
        };
      };
    };
}
