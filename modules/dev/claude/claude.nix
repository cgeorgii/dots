{ inputs, ... }:

{
  flake.modules.homeManager.claude =
    {
      config,
      pkgs,
      lib,
      link-dotfile,
      dotfile-path,
      ...
    }:

    let
      claude-pkgs = import inputs.nixpkgs-for-claude {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "claude-code"
          ];
      };

      claude = claude-pkgs.claude-code;

      claudeFiles = prefix: {
        "${prefix}/CLAUDE.md".source = link-dotfile ./CLAUDE.md;
        "${prefix}/keybindings.json".source = link-dotfile ./keybindings.json;
        "${prefix}/skills".source = link-dotfile ./skills;
        "${prefix}/agents".source = link-dotfile ./agents;
        "${prefix}/plugins/cgeorgii".source = link-dotfile ./plugins;
      };

      # Reproduces the home.file layout the workaround below avoids: a config
      # dir whose settings.json links into the store, which links on to a
      # writable file. Claude Code saving through that chain means upstream
      # fixed the bug and the workaround can go.
      canaryTarget = "${config.xdg.cacheHome}/claude-symlink-canary/settings.json";

      canaryHop = pkgs.runCommand "claude-symlink-canary-hop" { } ''
        mkdir $out
        ln -s ${canaryTarget} $out/settings.json
      '';

      canaryMarketplace = pkgs.writeTextDir ".claude-plugin/marketplace.json" (
        builtins.toJSON {
          name = "canary";
          owner.name = "canary";
          plugins = [ ];
        }
      );

      claude-symlink-canary = pkgs.writeShellApplication {
        name = "claude-symlink-canary";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.libnotify
        ];
        text = ''
          target=${lib.escapeShellArg canaryTarget}
          mkdir -p "$(dirname "$target")"
          echo '{}' > "$target"

          cfg=$(mktemp -d)
          trap 'rm -rf "$cfg"' EXIT
          ln -s ${canaryHop}/settings.json "$cfg/settings.json"

          if out=$(cd "$cfg" && CLAUDE_CONFIG_DIR="$cfg" ${lib.getExe claude} plugin marketplace add ${canaryMarketplace} 2>&1) \
            && grep -q '"canary"' "$target"; then
            msg="Claude Code ${claude.version} now saves settings.json through store symlinks. Drop the claudeSettings activation workaround in modules/dev/claude/claude.nix."
          elif grep -q EROFS <<<"$out"; then
            echo "claude-symlink-canary: still broken in ${claude.version}, keep the workaround"
            exit 0
          else
            msg="claude-symlink-canary is inconclusive for Claude Code ${claude.version}, check it by hand: $out"
          fi

          printf '\n%s\n!!! %s\n%s\n\n' "$(printf '!%.0s' {1..72})" "$msg" "$(printf '!%.0s' {1..72})" >&2
          export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
          notify-send -u critical "Claude Code symlink canary" "$msg" || true
          exit 1
        '';
      };
    in
    {
      home.packages = [
        claude
        claude-symlink-canary
      ];

      home.file = claudeFiles ".claude" // claudeFiles ".claude-work";

      # settings.json is linked straight at the checkout instead of through
      # home.file: Claude Code follows only one symlink hop and writes its
      # temp file beside that target, which in the store fails with EROFS, so
      # /config changes are silently dropped.
      home.activation.claudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        for dir in "$HOME/.claude" "$HOME/.claude-work"; do
          run mkdir -p "$dir"
          run ln -sfn ${lib.escapeShellArg (dotfile-path ./settings.json)} "$dir/settings.json"
        done
      '';

      home.activation.claudeSymlinkCanary = lib.hm.dag.entryAfter [ "claudeSettings" ] ''
        if [[ ! -v DRY_RUN ]]; then
          ${lib.getExe claude-symlink-canary} || true
        fi
      '';

      # Keep Claude Code's theme at truecolor inside tmux; without this it
      # special-cases $TMUX and clamps chalk to 256 colors, washing out
      # diff/comment text. Official opt-out for the upstream clamp.
      home.sessionVariables.CLAUDE_CODE_TMUX_TRUECOLOR = "1";
    };
}
