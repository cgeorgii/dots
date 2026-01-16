{ ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-d80ba783-00e7-4805-b96f-bb0205ee56aa".device =
    "/dev/disk/by-uuid/d80ba783-00e7-4805-b96f-bb0205ee56aa";
}
