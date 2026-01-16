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
    ./nix/desktop.nix
    ./nix/audio.nix
    ./nix/boot.nix
    ./nix/locale.nix
  ];

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
