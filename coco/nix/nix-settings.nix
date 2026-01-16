{ pkgs, ... }:

{
  nix = {
    package = pkgs.nixVersions.stable;

    settings = {
      trusted-users = [
        "root"
        "cgeorgii"
      ];
      auto-optimise-store = true;

      # Performance: parallel downloads from binary cache
      max-jobs = "auto";
      http-connections = 128;
      max-substitution-jobs = 16;

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "zeuslogics-nix-cache-github:RpfcOgIp6w2cvPyhTfErGcWkR9QSHc1gpp4UwyH3ovU="
        "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="

      ];
      substituters = [
        "https://haskell-language-server.cachix.org"
      ];
    };

    # Why is this necessary?
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes fetch-closure
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Needed to install unfree packages within flake.
  home-manager.useGlobalPkgs = true;

  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "discord"
        "dropbox"
        "firefox-bin"
        "firefox-bin-unwrapped"
        "firefox-release-bin-unwrapped"
        "slack"
        "spotify"
      ];
  };
}
