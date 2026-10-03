{ self, ... }:

{
  flake.modules.homeManager.dotfiles =
    { config, lib, ... }:
    let
      # Maps a path literal inside this flake (./config.kdl) to the same file
      # in the live checkout, so tools read the working copy, not the store.
      # A path literal doesn't have to exist, so check it does: a missing or
      # untracked file fails evaluation instead of becoming a dead link.
      dotfile-path =
        path:
        let
          root = "${toString self}/";
          file = toString path;
        in
        assert lib.assertMsg (lib.hasPrefix root file) "dotfile-path: ${file} is outside the flake";
        assert lib.assertMsg (builtins.pathExists path)
          "dotfile-path: ${file} does not exist (is it tracked by git?)";
        "${config.home.homeDirectory}/dots/${lib.removePrefix root file}";
    in
    {
      _module.args = {
        inherit dotfile-path;

        # Out-of-store symlink to a file in the checkout: edits apply without
        # a rebuild.
        link-dotfile = path: config.lib.file.mkOutOfStoreSymlink (dotfile-path path);
      };
    };
}
