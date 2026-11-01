{ inputs, config, ... }:

let
  inherit (config) style;
in
{
  # [ref:2.1-noctalia-shell] The desktop shell around niri: bar, launcher,
  # notifications, lock screen and wallpaper in one process.
  flake.modules.homeManager.noctalia =
    {
      pkgs,
      lib,
      link-dotfile,
      ...
    }:
    let
      noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      home.packages = [ noctalia ];

      # Every *.toml here is merged in name order and hot-reloaded. tinty-render
      # writes tinty.toml (mode and wallpaper) and palettes/tinty.json.
      # What the Settings window saves. Noctalia writes through the link, so
      # changes made in the GUI land in the checkout and show up in git.
      # `force` replaces the regular file it creates on first start.
      xdg.stateFile."noctalia/settings.toml" = {
        source = link-dotfile ./settings.toml;
        force = true;
      };

      xdg.configFile = {
        "noctalia/config.toml".source = link-dotfile ./config.toml;
        # The font follows the shared style [ref:shared-style]
        "noctalia/style.toml".text = ''
          [shell]
          font_family = "${style.font.mono}"
        '';

        "niri/shell.kdl".text = ''
          binds {
              Mod+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
              Mod5+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
              Mod+S { spawn "noctalia" "msg" "panel-toggle" "control-center"; }

              // KeePassXC locks from the session_locked hook in config.toml
              F9 { spawn "noctalia" "msg" "session" "lock"; }
              F10 allow-when-locked=true { spawn "noctalia" "msg" "session" "lock-and-suspend"; }
          }

          window-rule {
              match app-id="dev.noctalia.Noctalia"
              open-floating true
              default-column-width { fixed 1080; }
              default-window-height { fixed 920; }
          }

          debug {
              // Lets notification actions activate their windows
              honor-xdg-activation-with-invalid-serial
          }
        '';
      };

      # A user unit, so apps it launches can run as their own transient units
      # (launch_apps_as_systemd_services) and survive a restart of the shell.
      systemd.user.services.noctalia = {
        Unit = {
          Description = "Noctalia desktop shell";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
          X-Restart-Triggers = [ "${noctalia}" ];
        };
        Service = {
          ExecStart = lib.getExe noctalia;
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
