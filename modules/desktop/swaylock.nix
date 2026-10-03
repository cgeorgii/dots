{
  flake.modules.nixos.swaylock =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.swaylock ];

      security.pam.services.swaylock = { };
    };

  flake.modules.homeManager.swaylock =
    { config, ... }:
    {
      programs.swaylock = {
        enable = true;
        settings = {
          image = "${config.home.homeDirectory}/dots/coco/wallpapers/02108_navajoland_1920x1080.jpg";
          scaling = "fill";
          show-failed-attempts = true;
        };
      };
    };
}
