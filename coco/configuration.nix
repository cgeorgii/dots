{ pkgs, ... }:

{
  # Import modules
  imports = [
    ./nix/network.nix
    ./nix/mullvad.nix
    ./nix/logseq.nix
    ./nix/fonts.nix
    ./nix/security.nix
    ./nix/input.nix
    ./nix/peripherals.nix
  ];

  networking.hostName = "coco"; # The codependent computer

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-d80ba783-00e7-4805-b96f-bb0205ee56aa".device =
    "/dev/disk/by-uuid/d80ba783-00e7-4805-b96f-bb0205ee56aa";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.extraHosts = ''
    127.0.0.1       zeus-bucket.localhost
    127.0.0.1       dev.zeuslogics.com
  '';

  # enable firewall and block all ports
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 3000 ];
  networking.firewall.allowedUDPPorts = [ ];

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

  environment.systemPackages = with pkgs; [
    bat
    dconf
    firefox
    gitFull
    git-lfs
    libsecret
    pass
    git-credential-manager
    pinentry-gnome3
    readline
    swaylock
    silver-searcher
    tmux
    wget
    wally-cli
    xclip
    # zenith
    gcc # Required for neovim-treesitter
    udiskie
  ];

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
    };
  };

  # Required for Wayland compositors
  security.polkit.enable = true;

  # Enable Niri window manager
  programs.niri.enable = true;

  programs.zsh = {
    enable = true;
  };

  # Run `captive-browser` from the terminal
  programs.captive-browser = {
    enable = true;

    # Replace "wlan0" with your actual wireless interface name
    # To find out the interface name, run `ip a`
    interface = "wlp0s20f3";

    # # Browser to use for the captive portal
    # browser = lib.getExe pkgs.firefox;
  };

  programs.light.enable = true;

  # Enable GNOME Keyring for credential storage
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  users.users.cgeorgii = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/cgeorgii";
    extraGroups = [
      "audio"
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  # Autologin with greetd
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "cgeorgii";
      };
    };
  };

  # Don't suspend when lid is closed (using external monitors)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable GVfs for virtual filesystem support (USB, MTP, network mounts)
  services.gvfs.enable = true;

  # Steam stuff
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  virtualisation.docker.enable = true;

  environment.variables.EDITOR = "nvim";

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
