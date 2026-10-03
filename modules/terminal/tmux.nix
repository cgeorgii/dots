{
  flake.modules.nixos.tmux =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.tmux ];
    };

  flake.modules.homeManager.tmux =
    { link-dotfile, ... }:
    {
      home.file.".tmux.conf".source = link-dotfile "tmux.conf";

      programs.tmux.newSession = true;

      programs.zsh.shellAliases = {
        tkill = "tmux kill-server";
        there = "tmux new-session -d -s $(basename \"$PWD\" | tr . -); tmux switch-client -t $(basename \"$PWD\" | tr . -) || tmux attach -t $(basename \"$PWD\" | tr . -);";
      };
    };
}
