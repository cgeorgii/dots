{
  flake.modules.nixos.files = {
    # Enable GVfs for virtual filesystem support (USB, MTP, network mounts)
    services.gvfs.enable = true;
  };

  flake.modules.homeManager.files =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kdePackages.breeze-icons # Icon theme for Dolphin
        kdePackages.dolphin # File manager (supports clipboard image paste)
        nemo # File manager
      ];

      xdg.mimeApps.defaultApplications = {
        # File manager
        "inode/directory" = "org.kde.dolphin.desktop";

        "application/zip" = "org.gnome.FileRoller.desktop";
      };

      # Show Dolphin as "Files" in fuzzel. Overrides the package's desktop
      # entry (same id, so the mimeApps default and D-Bus activation still
      # resolve); "dolphin" stays in Keywords so the old name still finds it.
      xdg.desktopEntries."org.kde.dolphin" = {
        name = "Files";
        genericName = "File Manager";
        comment = "Manage your files";
        exec = "dolphin %u";
        icon = "org.kde.dolphin";
        type = "Application";
        categories = [
          "Qt"
          "KDE"
          "System"
          "FileTools"
          "FileManager"
        ];
        mimeType = [ "inode/directory" ];
        settings = {
          Keywords = "files;file manager;dolphin;file management;file browsing;samba;network shares;Explorer;Finder;";
          InitialPreference = "10";
          StartupWMClass = "dolphin";
          "X-DBUS-ServiceName" = "org.kde.dolphin";
        };
      };
    };
}
