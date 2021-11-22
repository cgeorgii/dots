# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Berlin";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  nix.binaryCaches = [ "https://cache.nixos.org" "https://nixcache.reflex-frp.org" ];
  nix.binaryCachePublicKeys = [ "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" ];

  environment.variables.EDITOR = "nvim";

  nixpkgs.config.firefox.enableGnomeExtensions = true;
  environment.systemPackages = with pkgs; [
    firefox
    git
    gnomeExtensions.dash-to-dock
    vim
    wget
    xclip
    tmux
    ag
  ];

  users.users.corgi = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/corgi";
    extraGroups = [ "wheel" ];
  };

  fonts.fonts = with pkgs; [
    (pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; })
  ];

  home-manager.users.corgi = { pkgs, ...}: {
    home.packages = [
      pkgs.nodejs
      pkgs.neovim
      pkgs.hub
      pkgs.alacritty
      pkgs.fzf
      pkgs.starship
      pkgs.rbenv
      pkgs.autojump
    ];

    programs.autojump = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      autocd = true;
      initExtra = "
        bindkey -v '^P' history-beginning-search-backward
        bindkey -v '^N' history-beginning-search-forward
        bindkey '^A' beginning-of-line
        bindkey '^E' end-of-line
        bindkey '^B' vi-backward-blank-word
        bindkey '^F' vi-forward-blank-word
      ";

      shellAliases = {
        update = "sudo nixos-rebuild switch";
        edit = "sudoedit /etc/nixos/configuration.nix";
        there = "tmux new-session -As $(basename \"$PWD\" | tr . -)";
        git = "hub";
        g = "git";
        gst = "git status";
        gitconfig = "nvim ~/.gitconfig";
      };
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        character = {
          format = "$symbol ";
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vicmd_symbol = "[❮](bold red)";
        };

        battery.disabled = true;
        package.disabled = true;
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
