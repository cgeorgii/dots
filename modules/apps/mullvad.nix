{
  flake.modules.nixos.mullvad = {
    services.mullvad-vpn.enable = true;
    services.mullvad-vpn.gui.enable = true;
  };
}
