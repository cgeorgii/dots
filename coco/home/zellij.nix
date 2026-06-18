{ config, pkgs, ... }:

let
  lib = import ../lib.nix { inherit config; };

  zellij-autolock = pkgs.fetchurl {
    url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
    sha256 = "sha256-aclWB7/ZfgddZ2KkT9vHA6gqPEkJ27vkOVLwIEh7jqQ=";
  };
in
{
  home.packages = [ pkgs.zellij ];

  xdg.configFile = {
    "zellij/config.kdl".source = lib.link-dotfile "config/zellij/config.kdl";
    "zellij/plugins/zellij-autolock.wasm".source = zellij-autolock;
  };

  programs.zsh.shellAliases = {
    zj = "zellij";
    zja = "zellij attach";
    zjl = "zellij list-sessions";
    zjk = "zellij kill-session";
    zjhere = "zellij attach -c $(basename \"$PWD\" | tr . -)";
  };
}
