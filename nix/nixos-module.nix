self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.sylvaris;
  greet = cfg.greeter;
  json = pkgs.formats.json { };
  package = self.packages.${pkgs.stdenv.hostPlatform.system}.sylvaris;
  configDir = "/etc/sylvaris-greet";
  launch = pkgs.writeShellScript "sylvaris-greet" ''
    export XDG_CONFIG_HOME=${configDir}
    export SYLVARIS_GREET_STATE=/var/lib/sylvaris-greet
    ${lib.optionalString (greet.user != "") "export SYLVARIS_GREET_USER=${lib.escapeShellArg greet.user}"}
    ${lib.optionalString (greet.session != "") "export SYLVARIS_GREET_SESSION=${lib.escapeShellArg greet.session}"}
    ${lib.optionalString (greet.wallpaper != null) "export SYLVARIS_GREET_WALLPAPER=${greet.wallpaper}"}
    exec ${lib.getExe' pkgs.cage "cage"} -s -m last -- ${lib.getExe' package "sylvaris"} greet
  '';
in
{
  options.programs.sylvaris = {
    lock.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add the sylvaris PAM service that SylLock checks passwords with.";
    };

    greeter = {
      enable = lib.mkEnableOption "SylGreet as the greetd login screen, running in cage";

      user = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "User picked on the first start; afterwards the last user who logged in is picked.";
      };

      session = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "hyprland";
        description = "Wayland session file name (without .desktop) picked on the first start.";
      };

      wallpaper = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Image behind the login screen; defaults to the theme's wallpaper.";
      };

      settings = lib.mkOption {
        type = json.type;
        default = { };
        description = "config.json for the login screen, for example a theme or an avatar.";
      };

      themes = lib.mkOption {
        type = lib.types.attrsOf json.type;
        default = { };
        description = "Theme bundles the login screen can use, like programs.sylvaris.themes in Home Manager.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.lock.enable {
      security.pam.services.sylvaris = { };
    })
    (lib.mkIf greet.enable {
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${launch}";
          user = "greeter";
        };
      };
      systemd.tmpfiles.rules = [ "d /var/lib/sylvaris-greet 0750 greeter greeter -" ];
      environment.etc = lib.mkMerge [
        {
          "sylvaris-greet/sylvaris/config.json".source = json.generate "sylvaris-greet-config.json" (
            { version = 1; } // greet.settings
          );
        }
        (lib.mapAttrs' (
          name: theme:
          lib.nameValuePair "sylvaris-greet/sylvaris/themes/${name}.json" {
            source = json.generate "sylvaris-greet-theme-${name}.json" (
              {
                version = 1;
                id = name;
              }
              // theme
            );
          }
        ) greet.themes)
      ];
    })
  ];
}
