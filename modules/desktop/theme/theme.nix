{
  inputs,
  config,
  ...
}:

let
  inherit (config) style;
in
{
  flake.modules.homeManager.theme =
    {
      pkgs,
      config,
      lib,
      dotfile-path,
      ...
    }:

    let
      # Seeded on first setup, before darkman has applied anything
      darkDefault = "base16-gruvbox-dark-medium";

      # [tag:scheme-marks] keep/skip marks set with TAB in theme-menu. darkman
      # picks one kept scheme per day by date, so the theme rotates daily while
      # still flipping light<->dark at sunrise/sunset. Hot-reloaded, so marking
      # a scheme needs no rebuild.
      marks = dotfile-path ./scheme-marks;

      # "<id> <variant>" for every scheme tinty lists, so the picker and the
      # rotation can split schemes into light and dark without parsing YAML.
      variants = pkgs.runCommand "scheme-variants" { } ''
        shopt -s nullglob
        for f in ${inputs.schemes}/{base16,base24,tinted8}/*.{yaml,yml}; do
          dir="''${f%/*}"
          name="''${f##*/}"
          v="$(sed -n 's/^variant: *"\{0,1\}\([a-z]*\).*/\1/p' "$f")"
          echo "''${dir##*/}-''${name%.y*ml} ''${v:-dark}"
        done | sort >$out
      '';

      # tinty is the runtime theme engine. It exports the active palette into the
      # environment and runs our render hook; we point it at the flake's schemes
      # repo (declarative, offline — we never run `tinty sync`). XDG default paths.
      tinty = "${pkgs.tinty}/bin/tinty";
      tintyConfig = "${config.xdg.configHome}/tinted-theming/tinty/config.toml";
      tintyData = "${config.home.homeDirectory}/.local/share/tinted-theming/tinty";
      tintyApply = scheme: "${tinty} apply ${scheme} --config ${tintyConfig} --data-dir ${tintyData}";

      # darkman hook body: apply the day's scheme from the kept schemes of
      # `variant`, indexed by the day of the year so it advances once per
      # calendar day and wraps around. A failure only shows up in darkman's
      # journal, so surface it as a notification too.
      themeOfDay = variant: ''
        fail() {
          printf '%s\n' "$2" >&2
          ${pkgs.libnotify}/bin/notify-send -u critical -a darkman "$1" "$2"
          exit 1
        }
        schemes="$(${pkgs.gawk}/bin/awk -v v=${variant} '
          NR == FNR { if ($1 == "keep") k[$2] = 1; next }
          $2 == v && ($1 in k) { print $1 }
        ' ${lib.escapeShellArg marks} ${variants})"
        [ -n "$schemes" ] || fail "No ${variant} theme kept" "Mark some with TAB in theme-menu."
        set -- $schemes
        day="$(${pkgs.coreutils}/bin/date +%j)"
        idx="$(( (10#$day - 1) % $# + 1 ))"
        eval "scheme=\''${$idx}"
        out="$(${tinty} apply "$scheme" --config ${tintyConfig} --data-dir ${tintyData} 2>&1)" ||
          fail "Theme switch failed: $scheme" "$out"
      '';

      # [tag:tinty-render-wrapper] The render logic lives in a hot-reloadable dotfile so theming can be tweaked
      # without a rebuild; this thin wrapper only supplies the PATH the script needs
      # (darkman's systemd environment is too lean to find dconf/pkill/tmux).
      tinty-render = pkgs.writeShellApplication {
        name = "tinty-render";
        runtimeInputs = [
          pkgs.procps
          pkgs.dconf
          pkgs.tmux
          pkgs.systemd
          pkgs.dbus
        ];
        # The shared style, for the configs the script renders
        text = ''
          export STYLE_GTK_DARK=${lib.escapeShellArg style.gtk.dark}
          export STYLE_GTK_LIGHT=${lib.escapeShellArg style.gtk.light}
          export STYLE_ICONS=${lib.escapeShellArg style.icons.name}
          export STYLE_FONT=${lib.escapeShellArg style.font.mono}
          export STYLE_FONT_UI_SIZE=${toString style.font.uiSize}
          exec bash "${dotfile-path ./tinty-render.sh}" "$@"
        '';
      };

      # Pick any scheme interactively (overrides darkman until its next sun event)
      # and mark schemes keep/skip. The fzf logic lives in the hot-reloaded
      # theme-menu.sh; this wrapper supplies its PATH, data paths and the fzf
      # colours (noctalia runs it with `kitty -e`, outside a login shell).
      theme-menu = pkgs.writeShellApplication {
        name = "theme-menu";
        runtimeInputs = [
          pkgs.tinty
          pkgs.fzf
          pkgs.gawk
          pkgs.gnugrep
          pkgs.coreutils
        ];
        text = ''
          export FZF_DEFAULT_OPTS=${lib.escapeShellArg style.fzf.flag}" ''${FZF_DEFAULT_OPTS:-}"
          export THEME_MARKS=${lib.escapeShellArg marks}
          export THEME_VARIANTS=${variants}
          export TINTY_CONFIG=${tintyConfig}
          export TINTY_DATA=${tintyData}
          exec bash "${dotfile-path ./theme-menu.sh}" "$@"
        '';
      };
    in
    {
      services.darkman = {
        enable = true;
        settings = {
          lat = 52.52;
          lng = 13.405;
          usegeoclue = false;
        };
        # darkman drives the automatic light/dark switch by applying the day's
        # kept scheme of that variant; tinty's render hook repaints every consumer.
        darkModeScripts.theme = themeOfDay "dark";
        lightModeScripts.theme = themeOfDay "light";
      };

      # tinty config: no template items (we theme entirely through the palette the
      # hook receives in the environment), and one hook that renders + reloads.
      xdg.configFile."tinted-theming/tinty/config.toml".text = ''
        default-scheme = "${darkDefault}"
        items = []
        hooks = [ "${tinty-render}/bin/tinty-render" ]
      '';

      # [tag:active-wallpaper] One wallpaper per variant; tinty-render points
      # noctalia at the current one.
      xdg.dataFile."wallpaper/dark".source = style.wallpaper.dark;
      xdg.dataFile."wallpaper/light".source = style.wallpaper.light;

      home.packages = [
        pkgs.darkman
        pkgs.tinty
        theme-menu
      ];

      # Point tinty's schemes repo at the flake input (a read-only nix-store dir;
      # apply/init only ever read it). `ln -sfn` re-points the symlink without
      # descending into it. Seed the active theme files with the dark default ONLY
      # on first setup (no scheme applied yet), so kitty/noctalia/nvim have
      # their generated inputs before the first darkman run — but a later rebuild
      # never overrides the current light/dark choice. darkman maintains it after.
      home.activation.tintyTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${tintyData}/repos"
        run ln -sfn '${inputs.schemes}' "${tintyData}/repos/schemes"
        if [ ! -e "${tintyData}/current_scheme" ]; then
          run ${tintyApply darkDefault} || true
        elif [ ! -e "${config.xdg.configHome}/noctalia/tinty.toml" ]; then
          # Render the current scheme once for noctalia, added after it was applied
          run ${tinty} apply "$(${tinty} current --config ${tintyConfig} --data-dir ${tintyData})" \
            --config ${tintyConfig} --data-dir ${tintyData} || true
        fi
      '';
    };
}
