{
  # OpenVPN through NetworkManager, so noctalia lists and toggles the tunnels.
  # Connecting with an OTP is documented in [file:docs/manual/src/vpn.md]
  flake.modules.nixos.vpn =
    { config, pkgs, ... }:

    {
      networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

      # The work profile, translated from the Sophos .ovpn export. Its inline
      # <ca> and <cert> blocks are the two .crt files; the <key> block is the
      # only secret.
      sops.secrets.vpn-work-key = {
        sopsFile = ./work.key.sops;
        format = "binary";
      };

      networking.networkmanager.ensureProfiles.profiles.work = {
        connection = {
          id = "work";
          type = "vpn";
          autoconnect = false;
        };
        vpn = {
          service-type = "org.freedesktop.NetworkManager.openvpn";
          connection-type = "password-tls";
          remote = "212.184.76.164:8443:udp";
          verify-x509-name = "subject:CN=helmsauer-gruppe.de";
          ca = "${./work-ca.crt}";
          cert = "${./work.crt}";
          key = config.sops.secrets.vpn-work-key.path;
          cipher = "AES-256-GCM";
          auth = "SHA512";
          reneg-seconds = 0;
          username = "christian.georgii";
          # Ask for the password (with the OTP appended) on every connect
          password-flags = 2;
          # The key has no passphrase
          cert-pass-flags = 4;
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
}
