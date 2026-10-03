{
  flake.modules.homeManager.git =
    { link-dotfile, ... }:

    {
      home.file.".gitignore".source = link-dotfile ./gitignore;
      home.file."./code/tweag/.gitconfig".source = link-dotfile ./gitconfig-work;

      programs.git = {
        enable = true;
        lfs.enable = true;
        includes = [
          { path = "~/.gitconfig"; } # GH adds auth information to this file
          # delta light/dark theme, swapped by darkman. Included after [delta], so
          # it overrides. git re-reads config per invocation -> follows live.
          { path = "~/.config/delta/theme-active.gitconfig"; }
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
            credentialStore = "secretservice";
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
