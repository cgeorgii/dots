{ ... }:

{
  home-manager.users.cgeorgii = { lib, config, pkgs, ... }:
    # Using a string here instead of the direct path because otherwise a config with
    # flakes will not symlink but copy the files, making hot-reloading the config
    # impossible without a rebuild.
    let
      link-dotfile = file:
        config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/dots/dotfiles/${file}";
    in
    {
      home.file.".gitignore".source = link-dotfile "gitignore";
      home.file.".tmux.conf".source = link-dotfile "tmux.conf";
      home.file.".emacs".source = link-dotfile "emacs";
      home.file."./code/tweag/.gitconfig".source = link-dotfile "gitconfig-work";

      xdg.configFile = {
        "alacritty/alacritty.toml".source = link-dotfile "alacritty.toml";
        "nvim/legacy.vim".source = link-dotfile "nvim/legacy.vim";
        "nvim/init.lua".source = link-dotfile "nvim/init.lua";
        "nvim/coc-settings.json".source = link-dotfile "coc-settings.json";
        "sway/extra".source = link-dotfile "sway";
      };

      home.packages = with pkgs; [
        alacritty
        autojump
        bemenu
        chromium
        digikam
        discord
        dropbox
        entr
        eza
        fd
        fzf
        gh
        home-manager
        hub
        imagemagick
        keepassxc
        libreoffice
        libsForQt5.dolphin
        lua-language-server
        nemo
        neofetch
        nixpkgs-fmt
        pavucontrol
        ripgrep
        signal-desktop
        slack
        spotify
        starship
        sway-contrib.grimshot # Screenshot tool
        whatsapp-for-linux
        wl-clipboard
        xfce.thunar
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

      # For sharing the screen on firefox.
      home.sessionVariables = {
        XDG_CURRENT_DESKTOP = "sway";
      };

      programs.swaylock.enable = true;

      gtk = {
        enable = true;
        # theme = {
        #   name = "Gruvbox-Dark";
        #   package = pkgs.gruvbox-gtk-theme;
        # };
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        iconTheme = {
          name = "Mint-Y-Sand";
          package = pkgs.mint-y-icons;
        };
        # cursorTheme = {
        #   name = "Bibata-Original-Classic";
        #   package = pkgs.bibata-cursors;
        # };
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk";
      };

      wayland.windowManager.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
        config = rec {
          modifier = "Mod4";
          terminal = "alacritty";
          fonts = { names = [ "IosevkaTerm Nerd Font Mono" ]; size = 9.0; };
          menu = "bemenu-run";
          startup = [
            # Ensure that the environment variables are correctly set for the user
            # systemd units. This ensures all user units started after the command set the
            # variables, so keep it at the top of this file.
            { command = "exec systemctl --user import-environment "; }
            # Launch Firefox on start
            { command = "firefox"; }
            { command = "exec udiskie --smart-tray"; }
            { command = "dropbox start -i"; }
          ];
          input = {
            "type:pointer" = {
              natural_scroll = "enabled";
            };

            "type:touchpad" = {
              natural_scroll = "enabled";
              tap = "enabled";
            };

            "type:keyboard" = {
              xkb_options = "caps:escape";
            };
          };

          window.border = 1;

          keybindings = lib.mkOptionDefault {
            "F9" = "exec swaylock -f -c 000000";
            "F10" = "exec swaylock -f -c 000000 && systemctl suspend";
            "${modifier}+Shift+s" = "exec grimshot copy area";
          };

          colors =
            # TODO Unify these colors with the ones from alacritty.yaml
            let
              # magenta = "#b16286";
              # cyan = "#689d6a";
              white = "#ebdbb2";
              red = "#cc241d";
              black = "#282828";
              gray = "#928374";
              yellow = "#d79921";
              brightYellow = "#fabd2f";
            in
            {
              focused = {
                background = black;
                border = yellow;
                childBorder = yellow;
                indicator = brightYellow;
                text = white;
              };
              unfocused = {
                background = black;
                border = gray;
                childBorder = gray;
                indicator = gray;
                text = gray;
              };
              focusedInactive = {
                background = black;
                border = white;
                childBorder = black;
                indicator = black;
                text = gray;
              };
              urgent = {
                background = red;
                border = red;
                childBorder = red;
                indicator = red;
                text = white;
              };
              placeholder = {
                background = "#000000";
                border = "#000000";
                childBorder = "#000000";
                indicator = "#000000";
                text = white;
              };
            };
          bars =
            let
              # magenta = "#b16286";
              # cyan = "#689d6a";
              white = "#ebdbb2";
              red = "#cc241d";
              black = "#282828";
              gray = "#928374";
              yellow = "#d79921";
            in
            [
              {
                statusCommand = "${pkgs.i3status}/bin/i3status";
                fonts = { names = [ "Iosevka" ]; size = 9.0; };
                position = "bottom";
                colors = {
                  background = black;
                  separator = "#666666";
                  statusline = white;
                  activeWorkspace = {
                    border = gray;
                    background = gray;
                    text = black;
                  };
                  focusedWorkspace = {
                    border = black;
                    background = yellow;
                    text = black;
                  };
                  inactiveWorkspace = {
                    border = black;
                    background = black;
                    text = white;
                  };
                  urgentWorkspace = {
                    border = red;
                    background = red;
                    text = white;
                  };
                };
              }
            ];
        };
        extraConfig = ''
          include ~/.config/sway/extra
        '';
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
        autosuggestion = {
          enable = true;
        };
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
          # [[ NIX ]]
          nixos-update = "sudo nixos-rebuild switch";
          nixos-link = "sudo ln -s /home/cgeorgii/dots/* /etc/nixos";

          # [[ TMUX ]]
          tkill = "tmux kill-server";
          there = "tmux new-session -d -s $(basename \"$PWD\" | tr . -); tmux switch-client -t $(basename \"$PWD\" | tr . -) || tmux attach -t $(basename \"$PWD\" | tr . -);";

          # [[ GIT ]]
          git = "hub";
          g = "git";
          gst = "git status";
          gaa = "git add .";
          gan = "git add . -N";
          gitconfig = "nvim ~/.gitconfig";
          lg = "lazygit";

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
        extraConfig = {
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
        };
        delta = {
          enable = true;
          options = {
            navigate = true;
            syntax-theme = "gruvbox-dark";
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

      programs.jq = {
        enable = true;
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

      # home.pointerCursor = {
      #   name = "Adwaita";
      #   package = pkgs.gnome.adwaita-icon-theme;
      #   size = 24;
      #   x11 = {
      #     enable = true;
      #     defaultCursor = "Adwaita";
      #   };
      # };

      home.stateVersion = "21.11";
    };
}
