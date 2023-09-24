{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bat
    file
    firefox-wayland
    git
    git-lfs
    gnomeExtensions.dash-to-dock
    pass
    pinentry
    readline
    rnix-lsp
    silver-searcher
    tmux
    wget
    wally-cli
    xclip
    zenith
    gcc # Required for neovim-treesitter
    easyeffects # Required for shitty sounding speakers to be somewhat useful
    gnome.gnome-tweaks
  ];

  programs.zsh = {
    enable = true;
  };

  users.users.cgeorgii = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/cgeorgii";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  nix = {
    package = pkgs.nixFlakes;

    settings = {
      trusted-users = [ "root" "cgeorgii" "oco" ];
      auto-optimise-store = true;
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
        "zeuslogics-nix-cache-github:RpfcOgIp6w2cvPyhTfErGcWkR9QSHc1gpp4UwyH3ovU="
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://storage.googleapis.com/zeuslogics-nix-cache-github"
        "https://nixcache.reflex-frp.org"
      ];
    };

    # Why is this necessary?
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  networking.extraHosts =
    ''
      127.0.0.1       zeus-bucket.localhost
      127.0.0.1       dev.zeuslogics.com
    '';

  fonts.packages = with pkgs; [
    (pkgs.nerdfonts.override { fonts = [ "Iosevka" "IosevkaTerm" ]; })
  ];

  # Add fingerprint with `fprintd-enroll`
  # Disabled because of me new moonlander.
  # services.fprintd.enable = true;

  virtualisation.docker = {
    enable = true;
    # dockerCompat = true;
  };

  services.fwupd.enable = true;

  hardware.keyboard.zsa.enable = true;

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

  # If changing any of the keyboard settings for xkb, make sure to run:
  # $ gsettings reset org.gnome.desktop.input-sources xkb-options
  # $ gsettings reset org.gnome.desktop.input-sources sources
  # # sudo nixos-rebuild switch
  # $ reboot
  services.xserver = {
    exportConfiguration = true;
    layout = "us, us(intl)";
    xkbOptions = "grp:alts_toggle, caps:escape";
  };

  # enable firewall and block all ports
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];

  # enable antivirus clamav and
  # keep the signatures' database updated
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };

  environment.variables.EDITOR = "nvim";

  # Needed to install unfree packages within flake.
  home-manager.useGlobalPkgs = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
    "dropbox"
    "slack"
    "spotify"
    "discord"
  ];
}
