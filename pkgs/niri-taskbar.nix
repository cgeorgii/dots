{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  gtk3,
}:

rustPlatform.buildRustPackage {
  pname = "niri-taskbar";
  version = "0.4.0-niri-25.11";

  src = fetchFromGitHub {
    owner = "LawnGnome";
    repo = "niri-taskbar";
    rev = "c530349fae638141ec58a9d4db0816d950a9295a";
    hash = "sha256-PN+7s3KnbIdUSs+PmY3A80x//tIQu2aqaW/vN7gXTRU=";
  };

  cargoHash = "sha256-WRc1+ZVhiIfmLHaczAPq21XudI08CgVhlIhVcf0rmSw=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gtk3 ];

  installPhase = ''
    runHook preInstall
    install -Dm755 target/${stdenv.hostPlatform.rust.rustcTargetSpec}/release/libniri_taskbar.so $out/lib/libniri_taskbar.so
    runHook postInstall
  '';

  meta = {
    description = "Niri taskbar module for Waybar";
    homepage = "https://github.com/LawnGnome/niri-taskbar";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
