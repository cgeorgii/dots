{ config, lib, pkgs, ... }: {
  packages.repomix-to-clipboard = import ./package.nix { inherit pkgs; };

  apps.repomix-to-clipboard = {
    program = lib.getExe config.packages.repomix-to-clipboard;
  };
}
