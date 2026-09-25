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
  pipewire,
  python3,
  curl,
  libnotify,
  glib,
  sylvarisParts ? { },
}:

let
  python = python3.withPackages (ps: [ ps.cryptography ]);
  partTools = {
    bar = [
      pulseaudio
      pipewire
      python
      libnotify
    ];
    center = [
      wlr-randr
      networkmanager
      wlsunset
      pulseaudio
      pipewire
      python
      libnotify
      wl-clipboard
    ];
    clock = [
      pipewire
      python
      libnotify
      curl
    ];
    deck = [ ];
    diver = [
      pipewire
      python
      libnotify
    ];
    media = [
      pulseaudio
      pipewire
      python
    ];
    notify = [ ];
    pad = [ ];
    paper = [ ];
    power = [ ];
    lock = [ glib ];
    polkit = [ ];
    switcher = [ ];
    settings = [
      wlsunset
      pipewire
      python
      libnotify
      curl
    ];
    theme = [ ];
  };
  tools = lib.unique (
    [
      quickshell
      coreutils
      procps
      socat
    ]
    ++ lib.concatLists (lib.mapAttrsToList (name: lib.optionals (sylvarisParts.${name} or true)) partTools)
  );
in
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
      --prefix PATH : ${lib.makeBinPath tools}
    runHook postInstall
  '';

  passthru.parts = builtins.attrNames partTools;

  meta = {
    description = "Modular Quickshell desktop shell for Hyprland, niri and sway";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "sylvaris";
  };
}
