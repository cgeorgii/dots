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
          # The palette tinty-render writes. mako refuses to start if the
          # include is missing, so theme.nix seeds an empty one on activation.
          include = "~/.config/mako/theme-active";
        };
      };
    };

  flake.modules.homeManager.mako =
    { pkgs, ... }:
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
    };
}
