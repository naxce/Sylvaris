{
  description = "Sylvaris, a modular Quickshell desktop shell for Hyprland, niri and sway";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: rec {
        sylvaris = pkgs.callPackage ./nix/package.nix { };
        default = sylvaris;
      });

      homeManagerModules = {
        sylvaris = import ./nix/hm-module.nix self;
        default = self.homeManagerModules.sylvaris;
      };

      checks = forAll (pkgs: {
        tests =
          pkgs.runCommand "sylvaris-tests"
            {
              nativeBuildInputs = [
                pkgs.nodejs
                pkgs.qt6.qtdeclarative
                pkgs.findutils
                (pkgs.python3.withPackages (ps: [ ps.cryptography ]))
              ];
            }
            ''
              cd ${./.}
              node --test tests/*.test.mjs
              python3 -m unittest discover -s tests -p '*_test.py'
              find shell -name '*.qml' -print0 | xargs -0 qmllint -I ${pkgs.qt6.qtdeclarative}/lib/qt-6/qml -I ${pkgs.quickshell}/lib/qt-6/qml
              touch $out
            '';

        parts =
          let
            full = pkgs.callPackage ./nix/package.nix { };
            lean = full.override {
              sylvarisParts = {
                center = false;
                media = false;
              };
            };
          in
          pkgs.runCommand "sylvaris-parts" { } ''
            grep -q wlr-randr ${full}/bin/sylvaris
            grep -q networkmanager ${full}/bin/sylvaris
            grep -q wl-clipboard ${full}/bin/sylvaris
            grep -q wlsunset ${lean}/bin/sylvaris
            for tool in wlr-randr networkmanager wl-clipboard; do
              if grep -q "$tool" ${lean}/bin/sylvaris; then
                echo "$tool is still wrapped with center and media excluded"
                exit 1
              fi
            done
            touch $out
          '';
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nodejs
            pkgs.qt6.qtdeclarative
            pkgs.quickshell
            pkgs.sway-unwrapped
            pkgs.grim
            pkgs.wlr-randr
            pkgs.wlsunset
            pkgs.jq
            pkgs.socat
            pkgs.libnotify
            pkgs.wtype
            pkgs.wlrctl
            pkgs.dbus
          ];
        };
      });
    };
}
