{ config, ... }:

let
  lib = import ../lib.nix { inherit config; };
in
{
  home.file.".tmux.conf".source = lib.link-dotfile "tmux.conf";

  programs.tmux.newSession = true;
}
