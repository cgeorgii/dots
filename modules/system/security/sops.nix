{ inputs, ... }:

{
  # Secrets committed encrypted and decrypted to /run/secrets at activation.
  # Bootstrapping and editing them is documented in
  # [file:docs/manual/src/secrets.md]
  flake.modules.nixos.sops = {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    # The machine's own age key, created by hand once. There is no SSH host
    # key to derive one from, since sshd is not enabled.
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  # My age key lives only in KeePassXC; sops fetches it on each run.
  flake.modules.homeManager.sops =
    { pkgs, dotfile-path, ... }:
    let
      keepassxc-pkgs = import inputs.nixpkgs-for-keepassxc {
        system = pkgs.stdenv.hostPlatform.system;
      };

      # Pins the deps; the script itself stays an out-of-store dotfile.
      sops-age-key = pkgs.writeShellApplication {
        name = "sops-age-key";
        runtimeInputs = [
          keepassxc-pkgs.keepassxc
          pkgs.zenity
        ];
        text = ''exec bash "${dotfile-path ./sops-age-key.sh}" "$@"'';
      };
    in
    {
      home.packages = [ sops-age-key ];
      home.sessionVariables.SOPS_AGE_KEY_CMD = "sops-age-key";
    };
}
