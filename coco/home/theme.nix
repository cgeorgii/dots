{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/dots/coco/dotfiles";

  # Curated "theme of the day" rings. darkman picks one scheme per day by
  # date, so the theme rotates daily while still flipping light<->dark at
  # sunrise/sunset. Any base16/base24 id from the schemes repo works; edit
  # these lists to taste. `theme-menu` can still apply any scheme ad-hoc.
  darkSchemes = [
    "base16-gruvbox-dark-medium"
    "base16-nord"
    "base16-tokyo-night-dark"
    "base16-catppuccin-mocha"
    "base16-kanagawa"
    "base16-rose-pine"
    "base16-gruvbox-material-dark-medium"
  ];
  lightSchemes = [
    "base16-classic-light"
    "base16-default-light"
    "base16-flexoki-light"
    "base16-humanoid-light"
    "base16-grayscale-light"
    "base16-oxocarbon-light"
    "base16-selenized-light"
    "base16-equilibrium-light"
    "base16-cave-light"
    "base16-dune-light"
    "base16-gruvbox-light-soft"
    "base16-atelier-heath-light"
    "base16-precious-light-warm"
    "base16-atelier-estuary-light"
    "base16-everforest-light-soft"
    "base16-equilibrium-gray-light"
    "base16-horizon-terminal-light"
    "base16-gruvbox-material-light-hard"
    "base16-gruvbox-material-light-soft"
    "base16-gruvbox-material-light-medium"
  ];
  darkDefault = builtins.head darkSchemes;

  # tinty is the runtime theme engine. It exports the active palette into the
  # environment and runs our render hook; we point it at the flake's schemes
  # repo (declarative, offline — we never run `tinty sync`). XDG default paths.
  tinty = "${pkgs.tinty}/bin/tinty";
  tintyConfig = "${config.xdg.configHome}/tinted-theming/tinty/config.toml";
  tintyData = "${config.home.homeDirectory}/.local/share/tinted-theming/tinty";
  tintyApply = scheme: "${tinty} apply ${scheme} --config ${tintyConfig} --data-dir ${tintyData}";

  # darkman hook body: apply the day's scheme from `schemes`, indexed by the
  # day of the year so it advances once per calendar day and wraps around.
  themeOfDay = schemes: ''
    set -- ${lib.concatStringsSep " " schemes}
    day="$(${pkgs.coreutils}/bin/date +%j)"
    idx="$(( (10#$day - 1) % $# + 1 ))"
    eval "scheme=\''${$idx}"
    ${tinty} apply "$scheme" --config ${tintyConfig} --data-dir ${tintyData}
  '';

  # The render logic lives in a hot-reloadable dotfile so theming can be tweaked
  # without a rebuild; this thin wrapper only supplies the PATH the script needs
  # (darkman's systemd environment is too lean to find dconf/pkill/tmux).
  tinty-render = pkgs.writeShellApplication {
    name = "tinty-render";
    runtimeInputs = [
      pkgs.procps
      pkgs.dconf
      pkgs.tmux
      pkgs.systemd
    ];
    text = ''exec bash "${dotfiles}/bin/tinty-render.sh" "$@"'';
  };

  # fuzzel has no daemon or include directive, so it reads the rendered config
  # at launch. Falls back to defaults if the theme hasn't been rendered yet.
  fuzzel-themed = pkgs.writeShellScriptBin "fuzzel-themed" ''
    conf="$HOME/.config/fuzzel/fuzzel-active.ini"
    if [ -f "$conf" ]; then
      exec ${pkgs.fuzzel}/bin/fuzzel --config "$conf" "$@"
    else
      exec ${pkgs.fuzzel}/bin/fuzzel "$@"
    fi
  '';

  # Pick any scheme interactively (overrides darkman until its next sun event).
  # An fzf picker: Enter applies the highlighted scheme in place and keeps the
  # list open (so you can browse live — the terminal re-themes under fzf), Esc
  # closes. Opens with the current scheme highlighted. fzf inherits kitty's
  # (themed) ANSI colours, so the picker itself follows the active scheme.
  theme-menu = pkgs.writeShellScriptBin "theme-menu" ''
    list="$(${tinty} list --config ${tintyConfig} --data-dir ${tintyData})"
    cur="$(${tinty} current --config ${tintyConfig} --data-dir ${tintyData} 2>/dev/null)"
    idx="$(printf '%s\n' "$list" | ${pkgs.gnugrep}/bin/grep -nxF -- "$cur" | ${pkgs.coreutils}/bin/cut -d: -f1)"
    args=(
      --layout=reverse
      --prompt 'theme > '
      --header 'enter: apply   esc: close'
      --bind "enter:execute-silent(${tinty} apply {} --config ${tintyConfig} --data-dir ${tintyData})"
    )
    [ -n "$idx" ] && args+=(--bind "load:pos($idx)")
    printf '%s\n' "$list" | ${pkgs.fzf}/bin/fzf "''${args[@]}" || true
  '';
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
    # scheme from the matching ring; tinty's render hook repaints every consumer.
    darkModeScripts.theme = themeOfDay darkSchemes;
    lightModeScripts.theme = themeOfDay lightSchemes;
  };

  # tinty config: no template items (we theme entirely through the palette the
  # hook receives in the environment), and one hook that renders + reloads.
  xdg.configFile."tinted-theming/tinty/config.toml".text = ''
    default-scheme = "${darkDefault}"
    items = []
    hooks = [ "${tinty-render}/bin/tinty-render" ]
  '';

  home.packages = [
    pkgs.darkman
    pkgs.tinty
    fuzzel-themed
    theme-menu
  ];

  # Point tinty's schemes repo at the flake input (a read-only nix-store dir;
  # apply/init only ever read it). `ln -sfn` re-points the symlink without
  # descending into it. Seed the active theme files with the dark default ONLY
  # on first setup (no scheme applied yet), so waybar/kitty/fuzzel/nvim have
  # their generated inputs before the first darkman run — but a later rebuild
  # never overrides the current light/dark choice. darkman maintains it after.
  home.activation.tintyTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${tintyData}/repos"
    run ln -sfn '${inputs.schemes}' "${tintyData}/repos/schemes"
    if [ ! -e "${tintyData}/current_scheme" ]; then
      run ${tintyApply darkDefault} || true
    fi
  '';
}
