{
  self,
  inputs,
  ...
}:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.swaylock = inputs.wrapper-modules.wrappers.swaylock.wrap {
        inherit pkgs;
        settings = {
          # Follows the light/dark variant; swaylock expands ~ [ref:active-wallpaper]
          image = "~/.local/share/wallpaper/active";
          scaling = "fill";
          show-failed-attempts = true;
        };
      };
    };

  flake.modules.nixos.swaylock =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    # Part of the classic shell [ref:desktop-shell]
    lib.mkIf (config.desktop.shell == "classic") {
      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.swaylock ];

      security.pam.services.swaylock = { };
    };
}
