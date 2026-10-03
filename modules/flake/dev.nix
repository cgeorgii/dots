{ inputs, ... }:

{
  perSystem =
    {
      system,
      config,
      final,
      ...
    }:
    {
      checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = inputs.self;
        hooks = {
          nixfmt.enable = true;
          deadnix.enable = true;
        };
      };

      devShells.default = final.mkShell {
        inherit (config.checks.pre-commit-check) shellHook;
        name = "coco-dev";
        packages = [
          final.nil
          final.git-bug
        ];
      };
    };
}
