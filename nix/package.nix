{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  wlr-randr,
  wlsunset,
  networkmanager,
  pulseaudio,
  wl-clipboard,
  coreutils,
  procps,
  socat,
}:

stdenvNoCC.mkDerivation {
  pname = "sylvaris";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../shell
      ../bin
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sylvaris
    cp -r shell/. $out/share/sylvaris/
    install -Dm755 bin/sylvaris $out/bin/sylvaris
    wrapProgram $out/bin/sylvaris \
      --set-default SYLVARIS_DIR $out/share/sylvaris \
      --prefix PATH : ${
        lib.makeBinPath [
          quickshell
          wlr-randr
          wlsunset
          networkmanager
          pulseaudio
          wl-clipboard
          coreutils
          procps
          socat
        ]
      }
    runHook postInstall
  '';

  meta = {
    description = "Modular Quickshell desktop shell for Hyprland, niri and sway";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "sylvaris";
  };
}
