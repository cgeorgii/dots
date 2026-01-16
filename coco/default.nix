{ inputs, ... }:

{
  imports = [
    # Nix settings (must come first for unfree packages)
    ./nix/nix-settings.nix

    # Hardware configuration
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

    # System configuration
    ./configuration.nix

    # Home-manager
    inputs.home-manager.nixosModules.home-manager
    ./home/cgeorgii.nix
  ];
}
