{ inputs, ... }:

{
  # Forward flake inputs (e.g. schemes) into home-manager modules.
  home-manager.extraSpecialArgs = { inherit inputs; };

  home-manager.users.cgeorgii =
    {
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

      discord-pkgs = import inputs.nixpkgs-for-discord {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "discord"
          ];
      };

      element-desktop-pkgs = import inputs.nixpkgs-for-element-desktop {
        system = pkgs.stdenv.hostPlatform.system;
      };

      keepassxc-pkgs = import inputs.nixpkgs-for-keepassxc {
        system = pkgs.stdenv.hostPlatform.system;
      };

    in
    {
      imports = [
        ./git.nix
        ./theme.nix
        ./tmux.nix
        ./zellij.nix
        ./claude.nix
        inputs.niri-taskbar.homeManagerModules.default
      ];

      xdg.configFile = {
        # Link the entire nvim directory structure
        "nvim".source = link-dotfile "nvim";
        "niri/config.kdl".source = link-dotfile "config/niri/config.kdl";
        # fuzzel-{dark,light}.ini are generated from the shared palette in theme.nix
        "waybar/config".source = link-dotfile "config/waybar/config.json";
        "waybar/style.css".source = link-dotfile "config/waybar/style.css";
        "jjui/config.toml".source = link-dotfile "config/jjui/config.toml";
        "jjui/themes".source = link-dotfile "config/jjui/themes";
        "workmux/config.yaml".source = link-dotfile "config/workmux/config.yaml";
      };

      programs.niri-taskbar.enable = true;

      home.packages = with pkgs; [
        autojump
        cachix
        chromium
        claude-pkgs.claude-code
        devenv
        digikam
        discord-pkgs.discord
        element-desktop-pkgs.element-desktop
        maestral
        maestral-gui
        entr
        eza
        fd
        fuzzel # App launcher for Niri
        fzf
        gh
        glab
        home-manager
        hub
        imagemagick
        imv
        jjui
        jujutsu
        keepassxc-pkgs.keepassxc
        libreoffice
        lua-language-server
        nemo # File manager
        neofetch
        nixfmt
        pavucontrol
        ripgrep
        signal-pkgs.signal-desktop
        spotify-pkgs.spotify
        starship
        swaybg # Wallpaper manager for Niri
        tree
        waybar
        inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default
        wasistlos
        whispering
        wl-clipboard
        xwayland-satellite # XWayland support for Niri
      ];

      # lazygit's theme is rendered at runtime by tinty (see coco/home/theme.nix
      # and dotfiles/bin/tinty-render.sh). Keeping `settings` empty means
      # home-manager installs the package but leaves config.yml to the theme
      # renderer, which owns that file.
      programs.lazygit.enable = true;

      # Session variables (XDG_CURRENT_DESKTOP set by compositor)
      home.sessionVariables = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = "24";
        # Keep Claude Code's theme at truecolor inside tmux; without this it
        # special-cases $TMUX and clamps chalk to 256 colors, washing out
        # diff/comment text. Official opt-out for the upstream clamp.
        CLAUDE_CODE_TMUX_TRUECOLOR = "1";
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
        # gruvbox-gtk-theme ships both Gruvbox-Dark and Gruvbox-Light; darkman
        # swaps between them at runtime via the gtk-theme gsetting. This is only
        # the boot default.
        theme = {
          name = "Gruvbox-Dark";
          package = pkgs.gruvbox-gtk-theme;
        };
        iconTheme = {
          name = "Mint-Y-Sand";
          package = pkgs.mint-y-icons;
        };
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        # No static prefer-dark hint: the light/dark choice is driven at runtime
        # by darkman through the color-scheme gsetting and the gtk-theme name.
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk";
      };

      programs.kitty = {
        enable = true;
        themeFile = "gruvbox-dark"; # boot default; overridden by the include below
        # Appended last so it wins over themeFile. darkman repoints
        # theme-active.conf at the dark/light theme and sends SIGUSR1 to reload.
        extraConfig = "include theme-active.conf";
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

        history = {
          size = 100000;
          save = 100000;
          share = false;
          ignoreAllDups = true;
          append = true;
        };

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
          ge = "nvim .git/COMMIT_EDITMSG";

          # [[ TRICORDER ]]
          tricorder = "~/.local/bin/tricorder";

          # [[ UTILS ]]
          cat = "bat";
          ls = "eza --git --icons -a --group-directories-first";
          w = "workmux";
          wz = "WORKMUX_BACKEND=zellij workmux";
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

      programs.password-store.enable = true;

      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };

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

      # Run waybar as a user service instead of a niri spawn-at-startup one-shot,
      # so it always comes back if it dies (e.g. the GTK reorder crash on SIGUSR2
      # theme reloads, or a manual kill). Restart=always covers SIGTERM too,
      # which Restart=on-failure ignores; an explicit `systemctl stop` still
      # stops it. ExecStartPre clears any stray instance before (re)starting.
      systemd.user.services.waybar = {
        Unit = {
          Description = "Waybar status bar";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
          Requisite = "graphical-session.target";
          # Never give up restarting: repeated reload-crashes while browsing
          # themes must not trip the default start-rate limiter and leave the
          # bar permanently down.
          StartLimitIntervalSec = 0;
        };
        Service = {
          # NixOS runs waybar as ".waybar-wrapped", so match that to actually
          # clear a stray instance (a plain "waybar" pattern never matches).
          ExecStartPre = "-${pkgs.procps}/bin/pkill -x .waybar-wrapped";
          ExecStart = "${pkgs.waybar}/bin/waybar";
          Restart = "always";
          RestartSec = 1;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

    };
}
