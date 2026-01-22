{ config }:

{
  # Creates an out-of-store symlink to a dotfile in coco/dotfiles/
  # This enables hot-reloading without rebuilds
  link-dotfile =
    file: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dots/coco/dotfiles/${file}";
}
