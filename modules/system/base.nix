{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        bat
        brightnessctl
        dconf
        gitFull
        git-lfs
        libsecret
        pass
        git-credential-manager
        pinentry-gnome3
        readline
        silver-searcher
        wget
        wally-cli
        xclip
        # zenith
        udiskie
      ];

      # Enable CUPS to print documents.
      services.printing.enable = true;

      # Enable GNOME Keyring for credential storage
      services.gnome.gnome-keyring.enable = true;
      security.pam.services.login.enableGnomeKeyring = true;
      security.pam.services.greetd.enableGnomeKeyring = true;

      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
      services.blueman.enable = true;

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
    };
}
