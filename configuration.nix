{ config, lib, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      <nixos-hardware/lenovo/thinkpad/x1/9th-gen>
      ./home/cgeorgii.nix
    ];

  environment.systemPackages = with pkgs; [
    bat
    file
    firefox-wayland
    git
    git-lfs
    gnomeExtensions.dash-to-dock
    readline
    rnix-lsp
    silver-searcher
    tmux
    wget
    xclip
    zenith
  ];

  users.users.cgeorgii = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/cgeorgii";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  nix = {
    trustedUsers = ["root" "cgeorgii"];
    package = pkgs.nixFlakes;
    trustedBinaryCaches = [ "https://cache.nixos.org" ];

    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
    '';
   };

  nix.autoOptimiseStore = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Necessary for encrypted disk
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/nvme0n1p2";
      preLVM = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tweag-laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.useDHCP = false;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  hardware.video.hidpi.enable = lib.mkDefault true;

  # Configure pipewire so loudspeakers are not useless
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Berlin";

  fonts.fonts = with pkgs; [
    (pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; })
  ];

  # Add fingerprint with `fprintd-enroll`
  services.fprintd.enable = true;

  virtualisation.docker.enable = true;

  # If changing any of the keyboard settings for xkb, make sure to rum:
  # $ gsettings reset org.gnome.desktop.input-sources xkb-options
  # $ gsettings reset org.gnome.desktop.input-sources sources
  # # sudo nixos-rebuild switch
  # $ reboot
  services.xserver= {
    layout = "us, us(intl)";
    xkbOptions = "grp:alts_toggle, caps:escape";
  };
  # Leave this as is
  system.stateVersion = "21.11"; # Did you read the comment?
}

