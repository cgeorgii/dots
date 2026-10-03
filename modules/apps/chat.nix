{ inputs, ... }:

{
  flake.modules.homeManager.chat =
    { pkgs, ... }:
    let
      signal-pkgs = import inputs.nixpkgs-for-signal {
        system = pkgs.stdenv.hostPlatform.system;
      };

      discord-pkgs = import inputs.nixpkgs-for-discord {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "discord"
          ];
      };

      element-desktop-pkgs = import inputs.nixpkgs-for-element-desktop {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    {
      home.packages = [
        discord-pkgs.discord
        element-desktop-pkgs.element-desktop
        signal-pkgs.signal-desktop
        pkgs.wasistlos
      ];

      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
      };
    };
}
