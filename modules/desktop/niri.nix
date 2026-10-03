{ inputs, ... }:

{
  flake.modules.nixos.niri =
    { pkgs, ... }:

    let
      niri-pkgs = import inputs.nixpkgs-for-niri {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    {
      xdg = {
        portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
          ];
        };
      };

      # Required for Wayland compositors
      security.polkit.enable = true;

      # Enable Niri window manager
      programs.niri = {
        enable = true;
        package = niri-pkgs.niri;
      };

      # Autologin with greetd
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${niri-pkgs.niri}/bin/niri-session";
            user = "cgeorgii";
          };
        };
      };

      services.upower.enable = true;
    };

  flake.modules.homeManager.niri =
    { pkgs, link-dotfile, ... }:
    {
      imports = [ inputs.niri-taskbar.homeManagerModules.default ];

      xdg.configFile."niri/config.kdl".source = link-dotfile "config/niri/config.kdl";

      programs.niri-taskbar.enable = true;

      home.packages = with pkgs; [
        fuzzel # App launcher for Niri
        swaybg # Wallpaper manager for Niri
        wl-clipboard
        xwayland-satellite # XWayland support for Niri
      ];

      # Enable xwayland-satellite for X11 app compatibility
      systemd.user.services.xwayland-satellite = {
        Unit = {
          Description = "Xwayland outside your Wayland";
          BindsTo = "graphical-session.target";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
        };
        Service = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          StandardOutput = "journal";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
