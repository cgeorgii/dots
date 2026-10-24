{ inputs, config, ... }:

let
  inherit (config) style;
in
{
  flake.modules.nixos.niri =
    { pkgs, lib, ... }:

    let
      niri-pkgs = import inputs.nixpkgs-for-niri {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    {
      # [tag:desktop-shell] What draws the bar, launcher, notifications, lock
      # screen and wallpaper around niri. Shell features gate themselves on it
      # (home modules through `osConfig`), so exactly one set runs.
      options.desktop.shell = lib.mkOption {
        type = lib.types.enum [
          "classic"
          "noctalia"
        ];
        default = "classic";
        description = ''
          `classic` is waybar, mako, fuzzel, swaylock and swaybg; `noctalia`
          replaces all of them.
        '';
      };

      config = {
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
    };

  flake.modules.homeManager.niri =
    {
      pkgs,
      lib,
      config,
      osConfig,
      link-dotfile,
      ...
    }:
    let
      classic = osConfig.desktop.shell == "classic";
    in
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

      # Included by config.kdl: the launcher and lock binds of the active
      # shell [ref:desktop-shell]. The noctalia feature writes its own.
      xdg.configFile."niri/shell.kdl" = lib.mkIf classic {
        text = ''
          binds {
              Mod+Space { spawn "fuzzel-themed"; }
              Mod5+Space { spawn "fuzzel-themed"; }

              // Lock (+ KeePassXC), and lock+suspend
              F9 { spawn "sh" "-c" "pgrep -x keepassxc >/dev/null && keepassxc --lock; swaylock -f"; }
              F10 allow-when-locked=true { spawn "sh" "-c" "pgrep -x keepassxc >/dev/null && keepassxc --lock; pgrep -x swaylock >/dev/null || swaylock -f && systemctl suspend"; }
          }
        '';
      };

      programs.niri-taskbar.enable = classic;

      # A user service rather than a spawn-at-startup, so tinty-render can
      # restart it onto the other variant's wallpaper [ref:active-wallpaper].
      systemd.user.services.swaybg = lib.mkIf classic {
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

      home.packages =
        with pkgs;
        [
          wl-clipboard
          xwayland-satellite # XWayland support for Niri
        ]
        ++ lib.optionals classic [
          fuzzel # App launcher for Niri
          swaybg # Wallpaper manager for Niri
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
