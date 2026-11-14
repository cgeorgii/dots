{ inputs, ... }:

{
  perSystem =
    {
      pkgs,
      lib,
      system,
      config,
      ...
    }:

    let
      workspace = lib.importTOML ./plugins/Cargo.toml;
      tileVersion = lib.removePrefix "=" workspace.workspace.dependencies.zellij-tile;
      plugins = workspace.workspace.members;
      cargoLock.lockFile = ./plugins/Cargo.lock;
      src = lib.fileset.toSource {
        root = ./plugins;
        fileset = lib.fileset.unions (
          [
            ./plugins/Cargo.toml
            ./plugins/Cargo.lock
          ]
          ++ map (p: ./plugins + "/${p}") plugins
        );
      };

      fenix = inputs.fenix.packages.${system};
      toolchain = fenix.combine [
        fenix.stable.cargo
        fenix.stable.rustc
        fenix.targets.wasm32-wasip1.stable.rust-std
      ];
      wasmPlatform = pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };
    in
    {
      # Every plugin in the workspace, as <name>.wasm. A plugin built against
      # another zellij-tile than the running zellij can fail to load, so a
      # zellij bump stops here until the workspace Cargo.toml follows it.
      packages.zellij-plugins =
        assert lib.assertMsg (tileVersion == pkgs.zellij.version)
          "zellij-plugins: zellij-tile is ${tileVersion} but zellij is ${pkgs.zellij.version}; bump modules/terminal/zellij/plugins/Cargo.toml";
        pkgs.stdenv.mkDerivation {
          pname = "zellij-plugins";
          inherit (workspace.workspace.package) version;
          inherit src;
          cargoDeps = wasmPlatform.importCargoLock cargoLock;
          nativeBuildInputs = [
            wasmPlatform.cargoSetupHook
            toolchain
          ];
          buildPhase = ''
            runHook preBuild
            cargo build --release --offline --target wasm32-wasip1 --workspace
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            for p in ${lib.escapeShellArgs plugins}; do
              install -Dm444 target/wasm32-wasip1/release/$p.wasm $out/$p.wasm
            done
            runHook postInstall
          '';
        };

      checks = {
        zellij-plugins = config.packages.zellij-plugins;
        # The pure logic, natively: zellij-tile is a wasm-only dependency
        zellij-plugins-tests = pkgs.rustPlatform.buildRustPackage {
          pname = "zellij-plugins-tests";
          inherit (workspace.workspace.package) version;
          inherit src cargoLock;
          cargoTestFlags = [ "--workspace" ];
        };
      };
    };
}
