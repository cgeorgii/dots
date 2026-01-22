{ config, ... }:

let
  lib = import ../lib.nix { inherit config; };
in
{
  home.file.".claude/CLAUDE.md".source = lib.link-dotfile "claude/CLAUDE.md";
  home.file.".claude/settings.json".source = lib.link-dotfile "claude/settings.json";
  home.file.".claude/skills".source = lib.link-dotfile "claude/skills";
}
