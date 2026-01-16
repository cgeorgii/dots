{ pkgs, ... }:

{
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
}
