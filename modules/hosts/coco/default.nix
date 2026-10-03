{ self, inputs, ... }:

{
  flake.nixosConfigurations.coco = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      self.modules.nixos.coco
    ];
  };
}
