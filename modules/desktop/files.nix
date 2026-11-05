{
  flake.modules.nixos.files = {
    # Enable GVfs for virtual filesystem support (USB, MTP, network mounts)
    services.gvfs.enable = true;
  };

  flake.modules.homeManager.files =
    { pkgs, link-dotfile, ... }:
    {
      home.packages = with pkgs; [
        kdePackages.breeze-icons # Icons Papirus falls back to in Dolphin
        kdePackages.dolphin # File manager (supports clipboard image paste)
        file-roller # Archive manager, the default for zips below
      ];

      xdg.mimeApps.defaultApplications = {
        # File manager
        "inode/directory" = "org.kde.dolphin.desktop";

        "application/zip" = "org.gnome.FileRoller.desktop";
      };

      # What Dolphin's settings window saves. Dolphin writes through the link, so
      # changes made in the GUI land in the checkout and show up in git. `force`
      # replaces the regular file it creates on first start.
      xdg.configFile."dolphinrc" = {
        source = link-dotfile ./dolphinrc;
        force = true;
      };

      # The toolbar layout, linked the same way.
      xdg.dataFile."kxmlgui5/dolphin/dolphinui.rc" = {
        source = link-dotfile ./dolphinui.rc;
        force = true;
      };

      # Show Dolphin as "Files" in the launcher. Overrides the package's desktop
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
