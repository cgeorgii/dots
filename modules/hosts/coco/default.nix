{ self, inputs, ... }:

{
  flake.nixosConfigurations.coco = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Apply our overlay module
      self.nixosModules.default

      self.modules.nixos.coco

      # Home-manager
      inputs.home-manager.nixosModules.home-manager
      ../../../coco/home/cgeorgii.nix
    ];
  };
}
