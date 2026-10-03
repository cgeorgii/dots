{
  self,
  inputs,
  config,
  ...
}:

let
  inherit (config) style;
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.mako = inputs.wrapper-modules.wrappers.mako.wrap {
        inherit pkgs;
        settings = {
          default-timeout = 10000;
          font = "${style.font.mono} ${toString style.font.size}";
          border-size = 2;
          border-radius = 0;
          padding = "10";
          # The palette tinty-render writes; activation seeds an empty one
          # [ref:mako-theme-seed].
          include = "~/.config/mako/theme-active";
        };
      };
    };

  flake.modules.homeManager.mako =
    { lib, pkgs, ... }:
    let
      mako = self.packages.${pkgs.stdenv.hostPlatform.system}.mako;
    in
    {
      home.packages = [ mako ];

      # mako starts on demand over D-Bus. The wrapper points its service file
      # at itself; link it where the session bus always looks, as
      # home-manager's services.mako did.
      xdg.dataFile."dbus-1/services/fr.emersion.mako.service".source =
        "${mako}/share/dbus-1/services/fr.emersion.mako.service";

      # The config is baked into the package, so a running mako from an older
      # package keeps its old settings (makoctl reload re-reads the old file).
      # Stop it so D-Bus starts the new one on the next notification; reload
      # the bus first, since it keeps using the service file it read earlier.
      home.activation.restartMako = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        busctl=${pkgs.systemd}/bin/busctl
        if owner="$($busctl --user status --no-pager org.freedesktop.Notifications 2>/dev/null)"; then
          pid="$(${pkgs.gnused}/bin/sed -n 's/^PID=//p' <<<"$owner")"
          cmd="$(${pkgs.gnused}/bin/sed -n 's/^CommandLine=//p' <<<"$owner")"
          case "$cmd" in
            "${mako}/bin/mako "*) ;;
            */bin/mako*)
              verboseEcho "Restarting mako to load its new config"
              run $busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
              run kill "$pid"
              ;;
          esac
        fi
      '';
    };
}
