{ config, pkgs, ... }:

{
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    bat
    file
    firefox
    git
    git-lfs
    gnomeExtensions.dash-to-dock
    readline
    rnix-lsp
    silver-searcher
    tmux
    vim
    wget
    xclip
    zenith
  ];

  fonts.fonts = with pkgs; [
    (pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; })
  ];

  # Add fingerprint with `fprintd-enroll`
  services.fprintd.enable = true;

  # If changing any of the keyboard settings for xkb, make sure to rum:
  # $ gsettings reset org.gnome.desktop.input-sources xkb-options
  # $ gsettings reset org.gnome.desktop.input-sources sources
  # # sudo nixos-rebuild switch
  # $ reboot
  services.xserver= {
    layout = "us, us(intl)";
    xkbOptions = "grp:alts_toggle, caps:escape";
  };
}
