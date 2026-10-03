{
  flake.modules.nixos.peripherals =
    { ... }:

    {
      services.fwupd.enable = true;

      hardware.keyboard.zsa.enable = true;
    };
}
