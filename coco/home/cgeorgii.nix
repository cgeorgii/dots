{ inputs, ... }:

{
  home-manager.users.cgeorgii =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cocoLib = import ../lib.nix { inherit config; };
      inherit (cocoLib) link-dotfile;

      claude-pkgs = import inputs.nixpkgs-for-claude {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "claude-code"
          ];
      };

      signal-pkgs = import inputs.nixpkgs-for-signal {
        system = pkgs.stdenv.hostPlatform.system;
      };

      spotify-pkgs = import inputs.nixpkgs-for-spotify {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "spotify"
          ];
      };

    in
    {
      imports = [
        ./git.nix
        ./tmux.nix
        ./claude.nix
      ];

      xdg.configFile = {
        # Link the entire nvim directory structure
        "nvim".source = link-dotfile "nvim";
        "niri/config.kdl".source = link-dotfile "config/niri/config.kdl";
        "fuzzel/fuzzel.ini".source = link-dotfile "config/fuzzel/fuzzel.ini";
        "waybar/config".source = link-dotfile "config/waybar/config.json";
        "waybar/style.css".source = link-dotfile "config/waybar/style.css";
      };

      home.packages = with pkgs; [
        autojump
        cachix
        chromium
        claude-pkgs.claude-code
        devenv
        digikam
        discord
        maestral
        maestral-gui
        entr
        eza
        font-awesome # For waybar icons
        fd
        fuzzel # App launcher for Niri
        fzf
        gh
        home-manager
        hub
        imagemagick
        imv
        jjui
        jujutsu
        keepassxc
        libreoffice
        lua-language-server
        nemo # File manager
        neofetch
        nixfmt-rfc-style
        pavucontrol
        ripgrep
        signal-pkgs.signal-desktop
        spotify-pkgs.spotify
        starship
        swaybg # Wallpaper manager for Niri
        tree
        waybar # Status bar for Niri
        wasistlos
        whispering
        wl-clipboard
        xwayland-satellite # XWayland support for Niri
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

      # Session variables (XDG_CURRENT_DESKTOP set by compositor)
      home.sessionVariables = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = "24";
      };

      # Default applications for file types
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          # File manager
          "inode/directory" = "nemo.desktop";

          # Web browser
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "text/html" = "firefox.desktop";
          "application/x-extension-htm" = "firefox.desktop";
          "application/x-extension-html" = "firefox.desktop";
          "application/x-extension-shtml" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "application/x-extension-xhtml" = "firefox.desktop";
          "application/x-extension-xht" = "firefox.desktop";

          # Other apps
          "application/zip" = "org.gnome.FileRoller.desktop";
          "x-scheme-handler/sgnl" = "signal.desktop";
          "x-scheme-handler/signalcaptcha" = "signal.desktop";
          "x-scheme-handler/logseq" = "Logseq.desktop";
          "image/jpeg" = "userapp-imv-B518F3.desktop";
        };
      };

      programs.swaylock = {
        enable = true;
        settings = {
          image = "${config.home.homeDirectory}/dots/coco/wallpapers/02108_navajoland_1920x1080.jpg";
          scaling = "fill";
          show-failed-attempts = true;
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "Gruvbox-Dark";
          package = pkgs.gruvbox-dark-gtk;
        };
        iconTheme = {
          name = "Mint-Y-Sand";
          package = pkgs.mint-y-icons;
        };
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk";
      };

      programs.kitty = {
        enable = true;
        themeFile = "gruvbox-dark";
        font = {
          name = "IosevkaTerm Nerd Font Mono";
          size = 14;
        };
        settings = {
          # Match alacritty's minimal look
          window_padding_width = 4;
          hide_window_decorations = true;
          # Cursor
          cursor_shape = "block";
          cursor_blink_interval = 0;
          # Scrollback
          scrollback_lines = 10000;
          # No audio bell
          enable_audio_bell = false;
          # Environment
          env = "EDITOR=nvim";
        };
      };

      programs.neovim = {
        enable = true;
        withNodeJs = true;
      };

      programs.autojump = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = true;

        config = {
          global = {
            hide_env_diff = true;
          };
        };
      };

      programs.zsh = {
        enable = true;
        autosuggestion = {
          enable = true;
        };
        enableCompletion = true;
        autocd = true;

        initContent = "
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

        export BAT_THEME=gruvbox-dark
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

      programs.jq = {
        enable = true;
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        defaultCommand = "fd --type f --hidden --exclude .git";
        fileWidgetCommand = "fd --type f --hidden --exclude .git";
        changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
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
          gcloud.disabled = true;

          git_branch = {
            format = "[$symbol$branch(:$remote_branch)]($style) ";
          };

          nix_shell = {
            format = "[$symbol$name]($style) ";
            impure_msg = "";
            symbol = "❄️ ";
          };

          # Language/environment modules - all use consistent format
          haskell.format = "[λ $version]($style) ";
        };
      };

      home.stateVersion = "21.11";

      # Enable pass-secret-service
      services.pass-secret-service = {
        enable = true;
        storePath = lib.mkForce "${config.home.homeDirectory}/.password-store";
      };
      programs.password-store.enable = true;

      # Enable xwayland-satellite for X11 app compatibility
      systemd.user.services.xwayland-satellite = {
        Unit = {
          Description = "Xwayland outside your Wayland";
          BindsTo = "graphical-session.target";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
        };
        Service = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          StandardOutput = "journal";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

    };
}
