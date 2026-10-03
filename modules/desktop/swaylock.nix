{ self, inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages.swaylock = inputs.wrapper-modules.wrappers.swaylock.wrap {
        inherit pkgs;
        settings = {
          image = ./wallpapers/02108_navajoland_1920x1080.jpg;
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
