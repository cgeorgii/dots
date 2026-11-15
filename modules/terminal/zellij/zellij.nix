{ self, config, ... }:

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

      plugins = self.packages.${pkgs.stdenv.hostPlatform.system}.zellij-plugins;

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
        # Built from plugins/
        "zellij/plugins/bar.wasm".source = "${plugins}/bar.wasm";
        "zellij/plugins/meld.wasm".source = "${plugins}/meld.wasm";
        "zellij/plugins/autoname.wasm".source = "${plugins}/autoname.wasm";
        "zellij/layouts/compact-git.kdl".source = link-dotfile ./layout.kdl;
      };

      programs.zsh.initContent = lib.mkMerge [
        # Sticky session roots: the first shell of each pane or tab starts in the
        # session's root (kept by zellij-tree.sh) instead of the focused pane's
        # directory. The marker keeps subshells, which inherit it, where they are.
        # A session without a root yet takes the directory of its first shell.
        (lib.mkOrder 500 ''
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
        '')

        # Pane titles, which also name the tabs (plugins/autoname): the command
        # while one runs, the directory at the prompt. Without the prompt half a
        # pane keeps the title of the last program that set one, such as nvim.
        (lib.mkOrder 1050 ''
          if [[ -n $ZELLIJ ]]; then
            autoload -Uz add-zsh-hook
            _zellij_title_prompt() { print -Pn '\e]2;%20<…<%~%<<\a' }
            _zellij_title_command() { print -rn -- $'\e]2;'"''${(V)1[1,40]}"$'\a' }
            add-zsh-hook precmd _zellij_title_prompt
            add-zsh-hook preexec _zellij_title_command
          fi
        '')
      ];

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
