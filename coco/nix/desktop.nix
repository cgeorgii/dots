{ pkgs, inputs, ... }:

let
  niri-pkgs = import inputs.nixpkgs-for-niri {
    system = pkgs.stdenv.hostPlatform.system;
  };
in
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
  programs.niri = {
    enable = true;
    package = niri-pkgs.niri;
  };

  # Autologin with greetd
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${niri-pkgs.niri}/bin/niri-session";
        user = "cgeorgii";
      };
    };
  };

  services.upower.enable = true;

  # Don't suspend when lid is closed (using external monitors)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
}
