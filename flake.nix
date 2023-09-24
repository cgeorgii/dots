{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager }: {

    nixosConfigurations = {
      coco = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Hardware config
          ./hardware-configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

          # Home-manager
          home-manager.nixosModules.home-manager

          # User config
          ./configuration.nix
          ./home/cgeorgii.nix
        ];
      };

      oco = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Hardware config
          ./hardware-configuration-oco.nix

          # Common config
          ./common.nix

          # System-specific config
          ./configuration-oco.nix

          # Home-manager
          home-manager.nixosModules.home-manager
          ./home/cgeorgii.nix
        ];
      };
    };
  };
}
