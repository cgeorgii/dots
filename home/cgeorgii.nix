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

      colorScheme = import ./colors.nix;
    in
    {
      home.file.".gitignore".source = link-dotfile "gitignore";
      home.file.".tmux.conf".source = link-dotfile "tmux.conf";
      home.file.".emacs".source = link-dotfile "emacs";
      home.file."./code/tweag/.gitconfig".source = link-dotfile "gitconfig-work";

      # # Export colors.yaml to be used by other applications like Alacritty
      # home.file."dots/colors.yaml".source = ./../dotfiles/colors.yaml;

      xdg.configFile = {
        "alacritty/alacritty.toml".source = link-dotfile "alacritty.toml";
        "sway/extra".source = link-dotfile "sway";
        # Link the entire nvim directory structure
        "nvim".source = link-dotfile "nvim";
      };

      home.packages = with pkgs; [
        alacritty
        autojump
        bemenu
        chromium
        claude-code
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
        tree
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
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        iconTheme = {
          name = "Mint-Y-Sand";
          package = pkgs.mint-y-icons;
        };
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
          fonts = { names = [ "IosevkaTerm Nerd Font Mono" ]; size = 11.0; };
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
              drag_lock = "enabled"; # This is necessary due to a bug: https://github.com/greshake/i3status-rust/issues/2171. Otherwise the keyboard variant in the swaybar will not be displayed correctly.
              natural_scroll = "enabled";
              tap = "enabled";
            };

            "type:keyboard" = {
              xkb_layout = "us,us(intl)";
              xkb_options = "caps:escape,grp:ctrl_space_toggle";
            };
          };

          window.border = 1;

          keybindings = lib.mkOptionDefault {
            "F9" = "exec swaylock -f -c 000000";
            "F10" = "exec swaylock -f -c 000000 && systemctl suspend";
            "${modifier}+Shift+s" = "exec grimshot copy area";
          };

          colors = {
            focused = {
              background = colorScheme.black;
              border = colorScheme.yellow;
              childBorder = colorScheme.yellow;
              indicator = colorScheme.bright_yellow;
              text = colorScheme.white;
            };
            unfocused = {
              background = colorScheme.black;
              border = colorScheme.gray;
              childBorder = colorScheme.gray;
              indicator = colorScheme.gray;
              text = colorScheme.gray;
            };
            focusedInactive = {
              background = colorScheme.black;
              border = colorScheme.white;
              childBorder = colorScheme.black;
              indicator = colorScheme.black;
              text = colorScheme.gray;
            };
            urgent = {
              background = colorScheme.red;
              border = colorScheme.red;
              childBorder = colorScheme.red;
              indicator = colorScheme.red;
              text = colorScheme.white;
            };
            placeholder = {
              background = "#000000";
              border = "#000000";
              childBorder = "#000000";
              indicator = "#000000";
              text = colorScheme.white;
            };
          };

          bars = [
            {
              statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-default.toml";
              trayOutput = "*";
              fonts = { names = [ "Iosevka" ]; size = 11.0; };
              position = "bottom";
              colors = {
                background = colorScheme.black;
                separator = "#666666";
                statusline = colorScheme.white;
                activeWorkspace = {
                  border = colorScheme.gray;
                  background = colorScheme.gray;
                  text = colorScheme.black;
                };
                focusedWorkspace = {
                  border = colorScheme.black;
                  background = colorScheme.yellow;
                  text = colorScheme.black;
                };
                inactiveWorkspace = {
                  border = colorScheme.black;
                  background = colorScheme.black;
                  text = colorScheme.white;
                };
                urgentWorkspace = {
                  border = colorScheme.red;
                  background = colorScheme.red;
                  text = colorScheme.white;
                };
              };
            }
          ];
        };
        extraConfig = ''
          include ~/.config/sway/extra
        '';
      };

      programs.i3status-rust = {
        enable = true;
        bars = {
          default = {
            icons = "awesome6";
            settings = {
              theme = {
                theme = "gruvbox-dark";
                overrides = {
                  # separator = " | ";
                  # Optionally customize separator colors
                  # separator_bg = "${colorScheme.black}"; # Match gruvbox-dark background
                  # separator_fg = "${colorScheme.white}"; # Match gruvbox-dark foreground
                };
              };
            };
            blocks = [
              # Keyboard layout
              {
                block = "keyboard_layout";
                driver = "sway";
                format = " $layout $variant ";
                theme_overrides = {
                  idle_bg = colorScheme.black; # Gruvbox dark background
                };
              }
              # Backlight/brightness control block
              {
                block = "backlight";
                device = "intel_backlight";
                step_width = 5;
                format = " ☀ {$brightness} ";
                invert_icons = false;
                theme_overrides = {
                  idle_bg = "#3c3836"; # Gruvbox light background
                };
              }
              # Wireless connection
              {
                block = "net";
                format = " $icon  {$ssid $frequency $signal_strength|Disconnected} ";
                format_alt = " $icon  {$ip/$ipv6|Disconnected} ";
                interval = 5;
              }
              # Disk space
              {
                block = "disk_space";
                path = "/";
                info_type = "available";
                alert_unit = "GB";
                interval = 60;
                warning = 20.0;
                alert = 10.0;
                format = " $icon  $used/$total ";
                theme_overrides = {
                  idle_bg = "#3c3836"; # Gruvbox light background
                };
              }
              # Memory usage
              {
                block = "memory";
                format = " $icon  $mem_used/$mem_total ";
                format_alt = " $icon  $mem_used_percents ";
              }
              # CPU usage
              {
                block = "cpu";
                interval = 1;
                format = " CPU $utilization ";
                theme_overrides = {
                  idle_bg = "#3c3836"; # Gruvbox light background
                  good_bg = "#3c3836"; # Gruvbox light background
                  info_bg = "#3c3836"; # Gruvbox light background
                };
              }
              # Battery
              {
                block = "battery";
                format = " $icon  $percentage {$time }";
                device = "BAT0";
                interval = 10;
                theme_overrides = {
                  idle_bg = colorScheme.black; # Gruvbox dark background
                  good_bg = colorScheme.black; # Gruvbox dark background
                  info_bg = colorScheme.black; # Gruvbox dark background
                };
              }
              # Time and date
              {
                block = "time";
                interval = 60;
                format = " $icon   $timestamp.datetime(f:'%a %d/%m %R')  ";
                theme_overrides = {
                  idle_bg = "#3c3836"; # Gruvbox light background
                };
              }
            ];
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
        autosuggestion = {
          enable = true;
        };
        enableCompletion = true;
        autocd = true;

        initContent = "
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
          gb = "git bug";

          # [[ UTILS ]]
          cat = "bat";
          ls = "eza --git --icons -a --group-directories-first";
          z = "zenith";
          rc = "repomix-to-clipboard";
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
          credential = {
            helper = "manager";
            credentialStore = "gpg";
          };
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

      home.stateVersion = "21.11";

      # Enable pass-secret-service
      services.pass-secret-service = {
        enable = true;
        storePath = "${config.home.homeDirectory}/.password-store";
      };
      programs.password-store.enable = true;
    };
}
