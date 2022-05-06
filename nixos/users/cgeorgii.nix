{ config, pkgs, ... }:

{
  imports =
    [ <home-manager/nixos> ];

  users.users.cgeorgii = {
    isNormalUser = true;
    shell = pkgs.zsh;
    home = "/home/cgeorgii";
    extraGroups = [ "wheel" ];
  };

  environment = {
    variables = {
      EDITOR = "nvim";
    };
  };

  home-manager.users.cgeorgii = { pkgs, ...}: {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "dropbox"
      "slack"
    ];

    home.packages = with pkgs; [
      alacritty
      albert
      autojump
      chromium
      diff-so-fancy
      direnv
      dropbox
      fzf
      gh
      hub
      keepassxc
      logseq
      neovim
      nix-direnv
      nodejs
      rbenv
      signal-desktop
      slack
      starship
    ];

    programs.autojump = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
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

        bindkey -e '^b' backward-char
        bindkey -e '^f' forward-char

        bindkey -e '^[b' backward-word
        bindkey -e '^[f' forward-word

        # Enter vim mode with ESC
        bindkey -e '^[' vi-cmd-mode

        export BAT_THEME=base16
      ";

      shellAliases = {
        update = "sudo nixos-rebuild switch";
        edit = "sudoedit /etc/nixos/configuration.nix";
        there = "tmux new-session -d -s $(basename \"$PWD\" | tr . -); tmux switch-client -t $(basename \"$PWD\" | tr . -);";
        git = "hub";
        g = "git";
        gst = "git status";
        gitconfig = "nvim ~/.gitconfig";
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
  };
}
