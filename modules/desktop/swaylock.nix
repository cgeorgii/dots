{
  self,
  inputs,
  config,
  ...
}:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.swaylock = inputs.wrapper-modules.wrappers.swaylock.wrap {
        inherit pkgs;
        settings = {
          image = config.style.wallpaper;
          scaling = "fill";
          show-failed-attempts = true;
        };
      };
    };

  flake.modules.nixos.swaylock =
    { pkgs, ... }:
    {
      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.swaylock ];

      security.pam.services.swaylock = { };
    };
}
