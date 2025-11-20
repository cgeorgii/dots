{ pkgs, ... }:

{
  networking.hostName = "coco"; # The codependent computer

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-d80ba783-00e7-4805-b96f-bb0205ee56aa".device = "/dev/disk/by-uuid/d80ba783-00e7-4805-b96f-bb0205ee56aa";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
      ];
      config = {
        niri = {
          default = [ "gnome" ];
        };
      };
    };
  };

  # Required for Wayland compositors
  security.polkit.enable = true;

  # Enable Niri window manager
  programs.niri.enable = true;

  # Enable GNOME Keyring for credential storage
  security.pam.services.login.enableGnomeKeyring = true;

  # Autologin
  services.getty.autologinUser = "cgeorgii";

  # Don't suspend when lid is closed (using external monitors)
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchExternalPower = "ignore";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Steam stuff
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.thermald.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
    cpufreq.max = 2800000;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
