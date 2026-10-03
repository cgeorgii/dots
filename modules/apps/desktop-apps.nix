{
  # Desktop apps that need no configuration of their own
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        chromium
        digikam
        imv
        libreoffice
        maestral
        maestral-gui
        pavucontrol
        whispering
      ];

      xdg.mimeApps.defaultApplications."image/jpeg" = "userapp-imv-B518F3.desktop";
    };
}
