{ inputs, ... }:

{
  perSystem =
    {
      system,
      config,
      pkgs,
      ...
    }:
    {
      checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = inputs.self;
        hooks = {
          nixfmt.enable = true;
          deadnix.enable = true;
          # Cross-references: no dangling refs or duplicate tags
          tagref.enable = true;
        };
      };

      devShells.default = pkgs.mkShell {
        inherit (config.checks.pre-commit-check) shellHook;
        name = "coco-dev";
        packages = [
          pkgs.nil
          pkgs.git-bug
          pkgs.tagref
        ];
      };
    };
}
