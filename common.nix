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
  ];

  fonts.fonts = with pkgs; [
    (pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; })
  ];

  # Remap caps lock to escape using the -m 1 flag to indicate only caps should be mapped to escape, not swapped
  services.interception-tools = {
    enable = true;
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1| ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
             EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };
}
