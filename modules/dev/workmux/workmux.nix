{ self, inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      # workmux's sidebar daemon polls `gh` for PR status with no way to turn it
      # off, and every call prompts for the SSH key. Put a failing `gh` first on
      # its PATH only: it then skips the repo and the PR status stays blank.
      packages.workmux =
        let
          upstream = inputs.workmux.packages.${pkgs.stdenv.hostPlatform.system}.default;
          gh-stub = pkgs.writeShellScriptBin "gh" "exit 1";
        in
        pkgs.symlinkJoin {
          name = "workmux-without-gh";
          paths = [ upstream ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/workmux --prefix PATH : ${gh-stub}/bin
          '';
        };
    };

  flake.modules.homeManager.workmux =
    { pkgs, link-dotfile, ... }:
    {
      home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.workmux ];

      xdg.configFile."workmux/config.yaml".source = link-dotfile ./config.yaml;

      programs.zsh.shellAliases = {
        w = "workmux";
        wz = "WORKMUX_BACKEND=zellij workmux";
      };
    };
}
