{
  description = "Declarative, baby!";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, home-manager }@inputs: {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
        ];
      };
    };

    homeConfigurations = {
      "cgeorgii@laptop" = home-manager.lib.homeManagerConfiguration rec {
        username = "cgeorgii";
        homeDirectory = "/home/${username}";
        system = "x86_64-linux";

        configuration = ./home-manager/home.nix;
        extraModules = [
          ./modules/home-manager
          # # Adds overlays
          # { nixpkgs.overlays = builtins.attrValues overlays; }
        ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
  };
}
