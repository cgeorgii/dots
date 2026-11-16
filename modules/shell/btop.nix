{
  flake.modules.homeManager.btop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # Pinned in btop.conf on every activation; btop owns the rest of the
      # file and saves its UI state there. "tinty" is the theme tinty renders
      # into themes/tinty.theme [file:modules/desktop/theme/tinty-render.sh].
      pinned = {
        color_theme = ''"tinty"'';
        theme_background = "false";
      };
    in
    {
      home.packages = [ pkgs.btop ];

      home.activation.btopTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        conf="${config.xdg.configHome}/btop/btop.conf"
        run mkdir -p "$(dirname "$conf")"
        run touch "$conf"
        ${lib.concatStrings (
          lib.mapAttrsToList (key: value: ''
            if ${pkgs.gnugrep}/bin/grep -q '^${key} =' "$conf"; then
              run ${pkgs.gnused}/bin/sed -i 's|^${key} = .*|${key} = ${value}|' "$conf"
            else
              run ${pkgs.bash}/bin/bash -c 'echo "$1" >>"$2"' _ ${lib.escapeShellArg "${key} = ${value}"} "$conf"
            fi
          '') pinned
        )}
      '';
    };
}
