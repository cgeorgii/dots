{
  flake.modules.homeManager.mako = {
    services.mako = {
      enable = true;
      settings = {
        default-timeout = 10000;
        font = "IosevkaTerm Nerd Font Mono 14";
        border-size = 2;
        border-radius = 0;
        padding = "10";
      };
    };
  };
}
