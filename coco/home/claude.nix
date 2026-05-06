{ config, ... }:

let
  lib = import ../lib.nix { inherit config; };

  claudeFiles = prefix: {
    "${prefix}/CLAUDE.md".source = lib.link-dotfile "claude/CLAUDE.md";
    "${prefix}/settings.json".source = lib.link-dotfile "claude/settings.json";
    "${prefix}/skills".source = lib.link-dotfile "claude/skills";
    "${prefix}/plugins/cgeorgii".source = lib.link-dotfile "claude/plugins";
  };
in
{
  home.file = claudeFiles ".claude" // claudeFiles ".claude-tweag";
}
