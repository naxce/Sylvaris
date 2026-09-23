self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.sylvaris;
  json = pkgs.formats.json { };
in
{
  options.programs.sylvaris = {
    enable = lib.mkEnableOption "Sylvaris, a modular Quickshell desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.sylvaris;
      defaultText = lib.literalExpression "sylvaris.packages.\${system}.sylvaris";
      description = "The Sylvaris package to install.";
    };

    settings = lib.mkOption {
      type = json.type;
      default = { };
      description = "Written to ~/.config/sylvaris/config.json. See the README for every key.";
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf json.type;
      default = { };
      description = "Theme bundles written to ~/.config/sylvaris/themes/<name>.json. The attribute name becomes the theme id.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      {
        "sylvaris/config.json".source = json.generate "sylvaris-config.json" ({ version = 1; } // cfg.settings);
      }
      (lib.mapAttrs' (
        name: theme:
        lib.nameValuePair "sylvaris/themes/${name}.json" {
          source = json.generate "sylvaris-theme-${name}.json" (
            {
              version = 1;
              id = name;
            }
            // theme
          );
        }
      ) cfg.themes)
    ];
  };
}
