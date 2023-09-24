{ config, lib, pkgs, ... }:

{
  networking.hostName = "coco"; # The codependent computer

  networking.useDHCP = false;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  hardware.pulseaudio.enable = true;

  time.timeZone = "Europe/Berlin";

  # Add fingerprint with `fprintd-enroll`
  # Disabled because of me new moonlander.
  # services.fprintd.enable = true;

  services.fwupd.enable = true;

  # Leave this as is
  system.stateVersion = "21.11"; # Did you read the comment?
}
