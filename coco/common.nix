{
  pkgs,
  ...
}:

{
  # Import modules
  imports = [
    ./nix/network.nix
    ./nix/mullvad.nix
    ./nix/logseq.nix
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

  programs.zsh = {
    enable = true;
  };

  security.pam.services.swaylock = { };

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

  nix = {
    package = pkgs.nixVersions.stable;

    settings = {
      trusted-users = [
        "root"
        "cgeorgii"
      ];
      auto-optimise-store = true;

      # Performance: parallel downloads from binary cache
      max-jobs = "auto";
      http-connections = 128;
      max-substitution-jobs = 16;

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "zeuslogics-nix-cache-github:RpfcOgIp6w2cvPyhTfErGcWkR9QSHc1gpp4UwyH3ovU="
        "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="

      ];
      substituters = [
        "https://haskell-language-server.cachix.org"
      ];
    };

    # Why is this necessary?
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes fetch-closure
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  networking.extraHosts = ''
    127.0.0.1       zeus-bucket.localhost
    127.0.0.1       dev.zeuslogics.com
  '';

  # fonts.packages = with pkgs; [
  #   nerd-fonts.iosevka
  #   nerd-fonts.iosevka-term
  # ];
  fonts = {
    packages = with pkgs; [
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term

      # Additional fonts for PDF compatibility
      liberation_ttf
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "Liberation Serif"
          "DejaVu Serif"
        ];
        sansSerif = [
          "Liberation Sans"
          "DejaVu Sans"
        ];
        monospace = [
          "IosevkaTerm Nerd Font Mono"
          "Iosevka Nerd Font Mono"
        ];
      };
    };
  };

  virtualisation.docker.enable = true;

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
    xkb = {
      layout = "us, us(intl)";
      options = "grp:alts_toggle, caps:escape, lv3:ralt_switch";
    };
  };

  # enable firewall and block all ports
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 3000 ];
  networking.firewall.allowedUDPPorts = [ ];

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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  environment.variables.EDITOR = "nvim";

  # Needed to install unfree packages within flake.
  home-manager.useGlobalPkgs = true;

  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "discord"
        "dropbox"
        "firefox-bin"
        "firefox-bin-unwrapped"
        "firefox-release-bin-unwrapped"
        "slack"
        "spotify"
      ];
  };
}
