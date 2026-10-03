{ inputs, ... }:

{
  flake.modules.homeManager.claude =
    { pkgs, link-dotfile, ... }:

    let
      claude-pkgs = import inputs.nixpkgs-for-claude {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "claude-code"
          ];
      };

      claudeFiles = prefix: {
        "${prefix}/CLAUDE.md".source = link-dotfile ./CLAUDE.md;
        "${prefix}/settings.json".source = link-dotfile ./settings.json;
        "${prefix}/keybindings.json".source = link-dotfile ./keybindings.json;
        "${prefix}/skills".source = link-dotfile ./skills;
        "${prefix}/agents".source = link-dotfile ./agents;
        "${prefix}/plugins/cgeorgii".source = link-dotfile ./plugins;
      };
    in
    {
      home.packages = [ claude-pkgs.claude-code ];

      home.file = claudeFiles ".claude" // claudeFiles ".claude-tweag";

      # Keep Claude Code's theme at truecolor inside tmux; without this it
      # special-cases $TMUX and clamps chalk to 256 colors, washing out
      # diff/comment text. Official opt-out for the upstream clamp.
      home.sessionVariables.CLAUDE_CODE_TMUX_TRUECOLOR = "1";
    };
}
