{
  flake.modules.nixos.swaylock =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.swaylock ];

      security.pam.services.swaylock = { };
    };

  flake.modules.homeManager.swaylock =
    { dotfile-path, ... }:
    {
      programs.swaylock = {
        enable = true;
        settings = {
          image = dotfile-path ./wallpapers/02108_navajoland_1920x1080.jpg;
          scaling = "fill";
          show-failed-attempts = true;
        };
      };
    };
}
