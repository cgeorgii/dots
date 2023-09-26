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
          ./coco/hardware-configuration.nix
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

          # Common config
          ./common.nix

          # System-specific config
          ./coco/configuration.nix

          # Home-manager
          home-manager.nixosModules.home-manager
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
          ./oco/configuration.nix

          # Home-manager
          home-manager.nixosModules.home-manager
          ./home/cgeorgii.nix
        ];
      };
    };
  };
}
