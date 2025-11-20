{ inputs, ... }:

{
  home-manager.users.cgeorgii =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    # Using a string here instead of the direct path because otherwise a config with
    # flakes will not symlink but copy the files, making hot-reloading the config
    # impossible without a rebuild.
    let
      link-dotfile =
        file: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dots/dotfiles/${file}";

      claude-pkgs = import inputs.nixpkgs-for-claude {
        system = pkgs.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "claude-code"
          ];
      };

      signal-pkgs = import inputs.nixpkgs-for-signal {
        system = pkgs.system;
      };

      spotify-pkgs = import inputs.nixpkgs-for-spotify {
        system = pkgs.system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (pkgs.lib.getName pkg) [
            "spotify"
          ];
      };

      zellij-autolock = pkgs.fetchurl {
        url = "https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm";
        sha256 = "sha256-aclWB7/ZfgddZ2KkT9vHA6gqPEkJ27vkOVLwIEh7jqQ=";
      };
    in
    {
      home.file.".gitignore".source = link-dotfile "gitignore";
      home.file.".tmux.conf".source = link-dotfile "tmux.conf";
      home.file.".emacs".source = link-dotfile "emacs";
      home.file."./code/tweag/.gitconfig".source = link-dotfile "gitconfig-work";
      home.file.".claude/CLAUDE.md".source = link-dotfile "claude/CLAUDE.md";
      home.file.".claude/settings.json".source = link-dotfile "claude/settings.json";
      home.file.".claude/commands".source = link-dotfile "claude/commands";

      # # Export colors.yaml to be used by other applications like Alacritty
      # home.file."dots/colors.yaml".source = ./../dotfiles/colors.yaml;

      xdg.configFile = {
        "alacritty/alacritty.toml".source = link-dotfile "alacritty.toml";
        # Link the entire nvim directory structure
        "nvim".source = link-dotfile "nvim";
        "zellij/config.kdl".source = link-dotfile "config/zellij/config.kdl";
        "zellij/plugins/zellij-autolock.wasm".source = zellij-autolock;
        "niri/config.kdl".source = link-dotfile "config/niri/config.kdl";
        "fuzzel/fuzzel.ini".source = link-dotfile "config/fuzzel/fuzzel.ini";
        "waybar/config".source = link-dotfile "config/waybar/config.json";
        "waybar/style.css".source = link-dotfile "config/waybar/style.css";
      };

      home.packages = with pkgs; [
        alacritty
        autojump
        cachix
        chromium
        claude-pkgs.claude-code
        devenv
        digikam
        discord
        dropbox
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
        tree
        waybar # Status bar for Niri
        whatsapp-for-linux
        wl-clipboard
        xwayland-satellite # XWayland support for Niri
        zellij
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
          image = "${config.home.homeDirectory}/dots/wallpapers/02108_navajoland_1920x1080.jpg";
          scaling = "fill";
          show-failed-attempts = true;
        };
      };

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
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk";
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

          # [[ ZELLIJ ]]
          zj = "zellij";
          zja = "zellij attach";
          zjl = "zellij list-sessions";
          zjk = "zellij kill-session";
          zjhere = "zellij attach -c $(basename \"$PWD\" | tr . -)";

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
        storePath = "${config.home.homeDirectory}/.password-store";
      };
      programs.password-store.enable = true;
    };
}
