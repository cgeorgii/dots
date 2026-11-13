{ config, ... }:

let
  inherit (config) style;
in
{
  flake.modules.homeManager.zellij =
    {
      lib,
      pkgs,
      link-dotfile,
      dotfile-path,
      ...
    }:

    let
      zellij-autolock = pkgs.fetchurl {
        url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
        sha256 = "sha256-aclWB7/ZfgddZ2KkT9vHA6gqPEkJ27vkOVLwIEh7jqQ=";
      };

      zjstatus = pkgs.fetchurl {
        url = "https://github.com/dj95/zjstatus/releases/download/v0.25.0/zjstatus.wasm";
        sha256 = "sha256-KCzqshnlbhkIyfrDOQckH+bD4e99hfqrPl9DjO+HuP4=";
      };

      zellij-tree = pkgs.writeShellApplication {
        name = "zellij-tree";
        runtimeInputs = with pkgs; [
          zellij
          fzf
          jq
          gawk
          gnused
          gnugrep
          git
          coreutils
        ];
        # The zellij server is spawned by niri, not a shell
        text = ''
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg style.fzf.flag}" ''${FZF_DEFAULT_OPTS:-}"
          exec bash "${dotfile-path ./zellij-tree.sh}" "$@"
        '';
      };
    in
    {
      home.packages = [
        pkgs.zellij
        zellij-tree
      ];

      xdg.configFile = {
        "zellij/config.kdl".source = link-dotfile ./config.kdl;
        "zellij/plugins/zellij-autolock.wasm".source = zellij-autolock;
        "zellij/plugins/zjstatus.wasm".source = zjstatus;
        "zellij/layouts/compact-git.kdl".source = link-dotfile ./layout.kdl;
      };

      # Sticky session roots: the first shell of each pane or tab starts in the
      # session's root (kept by zellij-tree.sh) instead of the focused pane's
      # directory. The marker keeps subshells, which inherit it, where they are.
      # A session without a root yet takes the directory of its first shell.
      programs.zsh.initContent = lib.mkOrder 500 ''
        if [[ -n $ZELLIJ_SESSION_NAME && -z $ZELLIJ_ROOTED ]]; then
          export ZELLIJ_ROOTED=1
          () {
            local file=''${XDG_RUNTIME_DIR:-/tmp}/zellij-roots/$ZELLIJ_SESSION_NAME root
            if [[ -r $file ]]; then
              root=$(<$file)
              [[ -d $root ]] && cd -q -- $root
            else
              mkdir -p -- $file:h && print -r -- $PWD >$file
            fi
          }
        fi
      '';

      programs.zsh.shellAliases = {
        zj = "zellij";
        zja = "zellij attach";
        zjl = "zellij list-sessions";
        zjk = "zellij kill-session";
        # Attach to or create the session for a directory (default: here)
        z = "zellij-tree here";
      };
    };
}
