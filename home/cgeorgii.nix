{ config, pkgs, ... }:

{
  imports =
    [ <home-manager/nixos> ];

  environment.variables.EDITOR = "nvim";

  home-manager.users.cgeorgii = { config, pkgs, ... }: {
    home.packages = with pkgs; [
      alacritty
      albert
      autojump
      beekeeper-studio
      calibre
      chromium
      dbeaver
      discord
      dropbox
      exa
      fd
      fzf
      gh
      hub
      imagemagick
      insomnia
      keepassxc
      libreoffice
      logseq
      neofetch
      niv
      protonvpn-cli
      protonvpn-gui
      ranger
      rbenv
      signal-desktop
      slack
      spotify
      starship
      whatsapp-for-linux
      wl-clipboard
    ];

    home.file.".gitignore".source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/gitignore;
    home.file.".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/tmux.conf;
    home.file.".emacs".source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/emacs;
    home.file."./projects/tweag/.gitconfig".source =
      config.lib.file.mkOutOfStoreSymlink ../dotfiles/gitconfig-work;

    xdg.configFile = {
      "alacritty/alacritty.yml".source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/alacritty.yml;
      "nvim/init.vim".source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/init.vim;
      "nvim/coc-settings.json".source = config.lib.file.mkOutOfStoreSymlink ../dotfiles/coc-settings.json;
    };

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "dropbox"
      "slack"
      "spotify"
      "discord"
    ];

    programs.lazygit = {
      enable = true;
      settings = {
        gui = {
          theme = {
            selectedLineBgColor = [ "reverse" ];
            selectedRangeBgColor = [ "reverse" ];
          };
        };
      };
    };

    programs.neovim = {
      enable = true;
      withNodeJs = true;
    };

    programs.tmux.newSession = true;

    programs.autojump = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      autocd = true;

      initExtra = "
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

        export BAT_THEME=gruvbox-dark

        # Make direnv shutup when entering a shell
        export DIRENV_LOG_FORMAT=
      ";

      shellAliases = {
        update = "sudo nixos-rebuild switch";
        upgrade = "sudo nix-channel --update";
        edit = "sudoedit /etc/nixos/configuration.nix";
        link = "sudo ln -s /home/cgeorgii/dots/* /etc/nixos";
        tkill = "tmux kill-server";
        there = "tmux new-session -d -s $(basename \"$PWD\" | tr . -); tmux switch-client -t $(basename \"$PWD\" | tr . -) || tmux attach -t $(basename \"$PWD\" | tr . -);";

        cat = "bat";
        git = "hub";
        g = "git";
        gst = "git status";
        gaa = "git add .";
        gan = "git add . -N";
        gitconfig = "nvim ~/.gitconfig";
        lg = "lazygit";
        ls = "exa --icons -a --group-directories-first";
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

    programs.git = {
      enable = true;
      lfs.enable = true;
      includes = [
        { path = "~/.gitconfig"; } # GH adds auth information to this file
        {
          path = "~/projects/tweag/.gitconfig";
          condition = "gitdir:~/projects/tweag/";
        }
      ];
      extraConfig = {
        user.name = "Christian Georgii";
        user.email = "cgeorgii@gmail.com";
        github.user = "cgeorgii";
        push.default = "simple";
        rerere.enable = true;
        branch.autosetuprebase = "always";
        core.excludefile = "~/.gitignore";
        core.excludesfile = "~/.gitignore";
        hub.protocol = "https";
      };
      delta = {
        enable = true;
        options = {
          navigate = true;
          syntax-theme = "TwoDark";
          light = false;
        };
      };
      aliases = {
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

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        character = {
          format = "$symbol ";
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vicmd_symbol = "[❮](bold red)";
        };

        battery.disabled = true;
        package.disabled = true;
      };
    };

    home.stateVersion = "21.11";
  };
}
