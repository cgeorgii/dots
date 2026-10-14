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
      config,
      link-dotfile,
      ...
    }:
    {
      imports = [ inputs.niri-taskbar.homeManagerModules.default ];

      xdg.configFile."niri/config.kdl".source = link-dotfile ./config.kdl;
      # Included by config.kdl, so the cursor follows the shared style [ref:shared-style]
      xdg.configFile."niri/style.kdl".text = ''
        cursor {
            xcursor-theme "${style.cursor.name}"
            xcursor-size ${toString style.cursor.size}
        }
      '';

      programs.niri-taskbar.enable = true;

      # A user service rather than a spawn-at-startup, so tinty-render can
      # restart it onto the other variant's wallpaper [ref:active-wallpaper].
      systemd.user.services.swaybg = {
        Unit = {
          Description = "Wallpaper";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
        };
        Service = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.xdg.dataHome}/wallpaper/active -m fill";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      home.packages = with pkgs; [
        fuzzel # App launcher for Niri
        swaybg # Wallpaper manager for Niri
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
