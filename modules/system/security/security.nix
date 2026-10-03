{ inputs, ... }:

{
  flake.modules.nixos.security =
    { pkgs, ... }:

    {
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = false;
      };

      # Plain OpenSSH agent; KeePassXC adds keys on unlock and removes them on lock.
      # gcr-ssh-agent (default with gnome-keyring) auto-loads keys from ~/.ssh,
      # bypassing that.
      programs.ssh.startAgent = true;

      # Needed for KeePassXC's "require user confirmation" (ssh-agent runs askpass).
      programs.ssh.enableAskPassword = true;
      # Confirmation dialogs focus "Deny" so a stray Enter doesn't approve a signature.
      programs.ssh.askPassword = toString (
        pkgs.writeShellScript "ssh-askpass-zenity" ''
          zenity=${pkgs.zenity}/bin/zenity
          case "$SSH_ASKPASS_PROMPT" in
            confirm)
              exec $zenity --question --title "SSH key use" --text "$1" --no-markup \
                --ok-label Allow --cancel-label Deny --default-cancel
              ;;
            none)
              exec $zenity --info --title "SSH" --text "$1" --no-markup
              ;;
            *)
              exec $zenity --entry --hide-text --title "SSH" --text "$1" --no-markup
              ;;
          esac
        ''
      );
      services.gnome.gcr-ssh-agent.enable = false;
    };

  flake.modules.homeManager.security =
    {
      pkgs,
      osConfig,
      link-dotfile,
      dotfile-path,
      ...
    }:
    let
      keepassxc-pkgs = import inputs.nixpkgs-for-keepassxc {
        system = pkgs.stdenv.hostPlatform.system;
      };

      # Pins the deps of the ssh `Match exec` hook; the script itself stays an
      # out-of-store dotfile so edits apply without a rebuild.
      ssh-keepassxc-unlock = pkgs.writeShellApplication {
        name = "ssh-keepassxc-unlock";
        runtimeInputs = [
          osConfig.programs.ssh.package
          osConfig.programs.niri.package
          keepassxc-pkgs.keepassxc
          pkgs.jq
          pkgs.coreutils
          pkgs.util-linux
          pkgs.procps
          pkgs.libnotify
          pkgs.systemd
        ];
        text = ''exec bash "${dotfile-path ./ssh-keepassxc-unlock.sh}" "$@"'';
      };
    in
    {
      home.file.".ssh/config".source = link-dotfile ./ssh-config;

      home.packages = [
        keepassxc-pkgs.keepassxc
        ssh-keepassxc-unlock
      ];

      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };
    };
}
