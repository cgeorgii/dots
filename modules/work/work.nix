{
  flake.modules.nixos.work = {
    imports = [ ./_vpn.nix ];

    # The work domain's internal CA, which signs the hosts behind the tunnel.
    # Firefox keeps its own store and installs it through a policy.
    security.pki.certificateFiles = [ ./helmsauer2000-ca.crt ];
  };
}
