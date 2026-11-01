{ inputs, config, ... }:

let
  inherit (config) style;
in
{
  flake.modules.nixos.niri =
    { pkgs, ... }:

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
    };

  flake.modules.homeManager.niri =
    {
      pkgs,
      link-dotfile,
      ...
    }:
    {
      xdg.configFile."niri/config.kdl".source = link-dotfile ./config.kdl;
      # Included by config.kdl, so the cursor follows the shared style [ref:shared-style]
      xdg.configFile."niri/style.kdl".text = ''
        cursor {
            xcursor-theme "${style.cursor.name}"
            xcursor-size ${toString style.cursor.size}
        }
      '';

      home.packages = with pkgs; [
        wl-clipboard
        xwayland-satellite # XWayland support for Niri
      ];

      # Enable xwayland-satellite for X11 app compatibility
      systemd.user.services.xwayland-satellite = {
        Unit = {
          Description = "Xwayland outside your Wayland";
          BindsTo = "graphical-session.target";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
        };
        Service = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          StandardOutput = "journal";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
