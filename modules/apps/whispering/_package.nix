{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  openssl,
  alsa-lib,
  libsoup_3,
  glib-networking,
  libayatana-appindicator,
  vulkan-loader,
  gst_all_1,
  ffmpeg,
}:

stdenv.mkDerivation rec {
  pname = "whispering";
  version = "7.7.2";

  src = fetchurl {
    url = "https://github.com/EpicenterHQ/epicenter/releases/download/v${version}/Whispering_${version}_amd64.deb";
    hash = "sha256-2wiLYYtghL6BhgGFSlI29UIVeOluOk0fK35fuAn7Zzo=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    openssl
    alsa-lib
    libsoup_3
    glib-networking
    libayatana-appindicator
    vulkan-loader
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share

    cp -r usr/bin/* $out/bin/
    cp -r usr/share/* $out/share/

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}
    )
  '';

  meta = {
    description = "Transparent transcription, truly yours";
    homepage = "https://epicenter.so/whispering/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "whispering";
  };
}
