{ config, ... }:

let
  lib = import ../lib.nix { inherit config; };
in
{
  home.file.".gitignore".source = lib.link-dotfile "gitignore";
  home.file."./code/tweag/.gitconfig".source = lib.link-dotfile "gitconfig-work";

  programs.git = {
    enable = true;
    lfs.enable = true;
    includes = [
      { path = "~/.gitconfig"; } # GH adds auth information to this file
      {
        path = "~/code/tweag/.gitconfig";
        condition = "gitdir:~/code/tweag/";
      }
    ];
    settings = {
      user.name = "Christian Georgii";
      user.email = "cgeorgii@gmail.com";
      github.user = "cgeorgii";
      push.default = "simple";
      rerere.enable = true;
      branch.autosetuprebase = "always";
      core.excludefile = "~/.gitignore";
      core.excludesfile = "~/.gitignore";
      hub.protocol = "ssh";
      push.autoSetupRemote = true;
      credential = {
        helper = "manager";
        credentialStore = "gpg";
      };
      alias = {
        b = "branch";
        cb = "checkout -b";
        pp = "pull --prune";
        co = "checkout";
        cm = "commit";
        cmm = "commit --allow-empty -m";
        cma = "commit --amend --no-edit";
        st = "status";
        du = "diff @{upstream}";
        di = "diff";
        dc = "diff --cached";
        dw = "diff --word-diff";
        dwc = "diff --word-diff --cached";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        review = "log master.. -p --reverse";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      syntax-theme = "gruvbox-dark";
      light = false;
    };
  };
}
