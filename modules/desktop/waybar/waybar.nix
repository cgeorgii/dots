{ config, ... }:

let
  inherit (config) style;
in
{
  flake.modules.homeManager.waybar =
    { pkgs, link-dotfile, ... }:
    {
      xdg.configFile = {
        "waybar/config".source = link-dotfile ./config.json;
        "waybar/style.css".source = link-dotfile ./style.css;
        # Imported by style.css, so the font follows the shared style [ref:shared-style]
        "waybar/fonts.css".text = ''
          * {
            font-family: "${style.font.mono}", "Font Awesome 6 Free", monospace;
            font-size: ${toString style.font.size}px;
          }
        '';
      };

      home.packages = [ pkgs.waybar ];

      # Run waybar as a user service instead of a niri spawn-at-startup one-shot,
      # so it always comes back if it dies (e.g. the GTK reorder crash on SIGUSR2
      # theme reloads, or a manual kill). Restart=always covers SIGTERM too,
      # which Restart=on-failure ignores; an explicit `systemctl stop` still
      # stops it. ExecStartPre clears any stray instance before (re)starting.
      systemd.user.services.waybar = {
        Unit = {
          Description = "Waybar status bar";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
          # Never give up restarting: repeated reload-crashes while browsing
          # themes must not trip the default start-rate limiter and leave the
          # bar permanently down.
          StartLimitIntervalSec = 0;
        };
        Service = {
          # NixOS runs waybar as ".waybar-wrapped", so match that to actually
          # clear a stray instance (a plain "waybar" pattern never matches).
          ExecStartPre = "-${pkgs.procps}/bin/pkill -x .waybar-wrapped";
          ExecStart = "${pkgs.waybar}/bin/waybar";
          Restart = "always";
          RestartSec = 1;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
