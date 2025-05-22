{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gitRepos;

  repoOpts = { ... }: {
    options = {
      url = mkOption {
        type = types.str;
        description = "Git repository URL";
        example = "https://github.com/username/repo.git";
      };

      path = mkOption {
        type = types.path;
        description = "Local path for the repository";
        example = "/home/user/repos/my-repo";
      };

      branch = mkOption {
        type = types.str;
        default = "main";
        description = "Branch to checkout";
      };

      recursive = mkOption {
        type = types.bool;
        default = true;
        description = "Clone submodules recursively";
      };
    };
  };
in
{
  options.services.gitRepos = {
    enable = mkEnableOption "git repository management";

    repositories = mkOption {
      type = types.attrsOf (types.submodule repoOpts);
      default = { };
      description = "Git repositories to manage";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.git-repos-sync = {
      description = "Sync git repositories";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ]; # Enable the service to run once on activation

      serviceConfig = {
        Type = "oneshot";
        User = "cgeorgii";
      };

      path = [ pkgs.git pkgs.openssh ];

      script = ''
        ${concatStringsSep "\n" (mapAttrsToList (_name: repo: ''
          if [ ! -d "${repo.path}" ]; then
            ${pkgs.git}/bin/git clone \
              ${optionalString repo.recursive "--recursive"} \
              -b ${repo.branch} \
              "${repo.url}" "${repo.path}"
          else
            cd "${repo.path}"
            # Check if repository is dirty
            if [ -n "$(${pkgs.git}/bin/git status --porcelain)" ]; then
              echo "Repository ${repo.path} has uncommitted changes, skipping update"
            else
              ${pkgs.git}/bin/git fetch
              ${pkgs.git}/bin/git checkout ${repo.branch}
              ${pkgs.git}/bin/git pull
              ${optionalString repo.recursive "${pkgs.git}/bin/git submodule update --init --recursive"}
            fi
          fi
        '') cfg.repositories)}
      '';
    };

    # Run on boot and periodically
    systemd.timers.git-repos-sync = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "30min";
      };
    };
  };
}
