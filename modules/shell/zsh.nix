{
  flake.modules.nixos.zsh = {
    programs.zsh = {
      enable = true;
    };
  };

  flake.modules.homeManager.zsh =
    { lib, pkgs, ... }:
    {
      programs.zsh = {
        enable = true;
        autosuggestion = {
          enable = true;
        };
        enableCompletion = true;
        autocd = true;

        history = {
          size = 100000;
          save = 100000;
          share = false;
          ignoreAllDups = true;
          append = true;
        };

        # After the tool integrations (order 1000), before the aliases (1100)
        initContent = lib.mkOrder 1050 "
        # Import systemd user environment variables (DISPLAY for XWayland)
        eval $(systemctl --user show-environment | grep -E '^(DISPLAY|WAYLAND_DISPLAY)=' | sed 's/^/export /')

        # Autosuggestion with async mode interferes with the history search functions
        # See https://github.com/zsh-users/zsh-autosuggestions/issues/619
        ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-beginning-search-backward-end history-beginning-search-forward-end)
        # Better history navigation with ^P and ^N
        autoload -U history-search-end
        zle -N history-beginning-search-backward-end history-search-end
        zle -N history-beginning-search-forward-end history-search-end
        bindkey -e '^P' history-beginning-search-backward-end
        bindkey -e '^N' history-beginning-search-forward-end

        # stop backward-kill-word on directory delimiter
        WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

        bindkey -e '^b' backward-char
        bindkey -e '^f' forward-char

        bindkey -e '^[b' backward-word
        bindkey -e '^[f' forward-word

        # Enter vim normal mode with ESC
        bindkey -e '^[' vi-cmd-mode

        # No delay entering vim normal mode
        export KEYTIMEOUT=1

        # bat probes the terminal background per invocation and picks the
        # matching gruvbox variant, so it follows the darkman theme in any shell.
        export BAT_THEME=auto
        export BAT_THEME_DARK=gruvbox-dark
        export BAT_THEME_LIGHT=gruvbox-light

        # function chpwd() {
        #   case $PWD in
        #     $HOME/code/tweag|$HOME/code/tweag/*) export CLAUDE_CONFIG_DIR=$HOME/.claude-tweag ;;
        #     *)                                   unset CLAUDE_CONFIG_DIR ;;
        #   esac
        # }
        # chpwd

        gh-pr-comments() {
          local PR REPO
          PR=$(gh pr view --json number --jq .number)
          REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
          gh api --paginate \"repos/$REPO/pulls/$PR/comments\" > /tmp/pr-inline.json
          gh api --paginate \"repos/$REPO/issues/$PR/comments\" > /tmp/pr-issue.json
          gh api --paginate \"repos/$REPO/pulls/$PR/reviews\" > /tmp/pr-reviews.json
          jq -s '([.[0][], .[1][]] | map({path, start_line, line, body})) + [.[2][] | select(.body != \"\") | {body}]' /tmp/pr-inline.json /tmp/pr-issue.json /tmp/pr-reviews.json > pr-comments.json
        }

        glab-mr-comments() {
          local BRANCH MR PROJECT
          BRANCH=$(git rev-parse --abbrev-ref HEAD)
          # Use glab api (not 'mr view -F json'): mr view runs the description through
          # the glamour markdown renderer, which mangles the JSON under command
          # substitution. Redirect to files for the same reason.
          glab api \"projects/:id/merge_requests?source_branch=$BRANCH\" > /tmp/mr-meta.json
          MR=$(jq '.[0].iid' /tmp/mr-meta.json)
          PROJECT=$(jq '.[0].project_id' /tmp/mr-meta.json)
          glab api --paginate \"projects/$PROJECT/merge_requests/$MR/notes\" > /tmp/mr-notes.json
          jq -s 'flatten | [.[] | select(.system != true and .body != \"\") | if .type == \"DiffNote\" then {path: .position.new_path, line: .position.new_line, body} else {body} end]' /tmp/mr-notes.json > mr-comments.json
        }
      ";

        shellAliases = {
          # [[ NIX ]]
          nixos-update = "sudo nixos-rebuild switch";
          nixos-link = "sudo ln -s /home/cgeorgii/dots/* /etc/nixos";

          # [[ GIT ]]
          git = "hub";
          g = "git";
          gst = "git status";
          gaa = "git add .";
          gan = "git add . -N";
          gitconfig = "nvim ~/.gitconfig";
          lg = "lazygit";
          gb = "git bug";
          ge = "nvim .git/COMMIT_EDITMSG";

          # [[ TRICORDER ]]
          tricorder = "~/.local/bin/tricorder";

          # [[ UTILS ]]
          cat = "bat";
          ls = "eza --git --icons -a --group-directories-first";
          z = "zenith";
        };

        plugins = with pkgs; [
          {
            name = "zsh-syntax-highlighting";
            src = fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-syntax-highlighting";
              rev = "0.6.0";
              sha256 = "0zmq66dzasmr5pwribyh4kbkk23jxbpdw4rjxx0i7dx8jjp2lzl4";
            };
            file = "zsh-syntax-highlighting.zsh";
          }
          {
            name = "zsh-autopair";
            src = fetchFromGitHub {
              owner = "hlissner";
              repo = "zsh-autopair";
              rev = "34a8bca0c18fcf3ab1561caef9790abffc1d3d49";
              sha256 = "1h0vm2dgrmb8i2pvsgis3lshc5b0ad846836m62y8h3rdb3zmpy1";
            };
            file = "autopair.zsh";
          }
        ];
      };
    };
}
