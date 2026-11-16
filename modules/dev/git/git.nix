{
  # Fetches from GitHub go over HTTPS with a read-only token; pushes stay on
  # SSH and keep KeePassXC's confirmation. Why, in
  # [file:docs/manual/src/ssh-keys.md] [ref:1.6-github-readonly-fetch]
  flake.modules.nixos.git = {
    sops.secrets.github-ro-token = {
      sopsFile = ./github-ro-token.sops;
      format = "binary";
      owner = "cgeorgii";
      mode = "0400";
    };
  };

  flake.modules.homeManager.git =
    {
      pkgs,
      lib,
      osConfig,
      link-dotfile,
      ...
    }:

    let
      # `git-ro-credential TOKEN_FILE USERNAME ACTION`: answers `get` with the
      # token file's contents and does nothing on `store` or `erase`, so git
      # can never overwrite or delete the token. `quit=1` stops git from
      # falling back to SSH_ASKPASS, which would pop a password dialog during
      # background fetches whenever the token is missing or not enough.
      git-ro-credential = pkgs.writeShellApplication {
        name = "git-ro-credential";
        text = ''
          token_file=''${1:?token file} username=''${2:?username} action=''${3:-}
          cat >/dev/null
          [[ $action == get ]] || exit 0
          if [[ -r $token_file ]]; then
            printf 'username=%s\npassword=%s\n' "$username" "$(<"$token_file")"
          fi
          echo quit=1
        '';
      };

      github-ssh = [
        "git@github.com:"
        "ssh://git@github.com/"
      ];
    in
    {
      home.file.".gitignore".source = link-dotfile ./gitignore;
      home.file."./code/work/.gitconfig".source = link-dotfile ./gitconfig-work;

      programs.git = {
        enable = true;
        lfs.enable = true;
        includes = [
          { path = "~/.gitconfig"; } # unmanaged; must not add a github.com credential helper
          # delta light/dark theme, swapped by darkman. Included after [delta], so
          # it overrides. git re-reads config per invocation -> follows live.
          { path = "~/.config/delta/theme-active.gitconfig"; }
          {
            path = "~/code/work/.gitconfig";
            condition = "gitdir:~/code/work/";
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
          # git applies pushInsteadOf to the remote's configured URL, not the
          # insteadOf result, so the SSH forms map to themselves for pushes.
          url."https://github.com/".insteadOf = github-ssh;
          url."git@github.com:".pushInsteadOf = github-ssh ++ [ "https://github.com/" ];
          # The empty value drops helpers configured before this one.
          credential."https://github.com".helper = [
            ""
            "${lib.getExe git-ro-credential} ${osConfig.sops.secrets.github-ro-token.path} x-access-token"
          ];
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
            e = "!nvim .git/COMMIT_EDITMSG";
          };
        };
      };

      # lazygit's theme is rendered at runtime by tinty (see modules/desktop/theme.nix
      # and dotfiles/bin/tinty-render.sh). Keeping `settings` empty means
      # home-manager installs the package but leaves config.yml to the theme
      # renderer, which owns that file.
      programs.lazygit.enable = true;

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          # light/dark + syntax-theme come from ~/.config/delta/theme-active.gitconfig
          # (darkman-swapped include), so they are not hardcoded here.
          pager = "less --mouse --wheel-lines=3 -R -F";
        };
      };
    };
}
