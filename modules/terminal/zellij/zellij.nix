{
  flake.modules.homeManager.zellij =
    {
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
        text = ''
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

      programs.zsh.shellAliases = {
        zj = "zellij";
        zja = "zellij attach";
        zjl = "zellij list-sessions";
        zjk = "zellij kill-session";
        zjhere = "zellij-tree here";
      };
    };
}
