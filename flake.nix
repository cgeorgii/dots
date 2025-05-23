{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";

    # Add flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = { system, config, pkgs, lib, ... }: {
        imports = [
          ./apps/repomix-to-clipboard/flake-module.nix
        ];

        # Checks for pre-commit hooks
        checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Formatting hooks
            nixpkgs-fmt.enable = true;
            # Check for common issues
            deadnix.enable = true;
          };
        };

        # Development shell with pre-commit hooks installed
        devShells.default = pkgs.mkShell {
          inherit (config.checks.pre-commit-check) shellHook;

          packages = [
            pkgs.repomix
            pkgs.git-bug
            config.packages.repomix-to-clipboard
          ];
        };
      };

      flake = {
        nixosConfigurations = {
          coco = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
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
