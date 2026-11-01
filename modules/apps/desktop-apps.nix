{
  # Desktop apps that need no configuration of their own
  flake.modules.homeManager.desktop-apps =
    { pkgs, ... }:
    let
      # Maestral prefers maestral_tray-<status>-symbolic theme icons over the
      # pixmap it otherwise sends. A symbolic name lets the bar tint the icon
      # with its foreground, so it follows light/dark.
      maestral-symbolic-icons = pkgs.runCommand "maestral-symbolic-icons" { } ''
        dir=$out/share/icons/hicolor/scalable/status
        mkdir -p $dir
        for svg in ${pkgs.maestral-gui}/lib/python3*/site-packages/maestral_qt/resources/maestral_tray-*-dark.svg; do
          name=$(basename "$svg" -dark.svg)
          cp "$svg" "$dir/$name-symbolic.svg"
        done
      '';
    in
    {
      home.packages = with pkgs; [
        chromium
        digikam
        imv
        libreoffice
        maestral
        maestral-gui
        maestral-symbolic-icons
        pavucontrol
      ];

      xdg.mimeApps.defaultApplications."image/jpeg" = "userapp-imv-B518F3.desktop";
    };
}
