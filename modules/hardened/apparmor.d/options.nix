# CuriOS AppArmor profiles — NixOS option declarations.
# Defines curios.hardened.apparmor-profiles.* options.

{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  modeType = types.enum [ "complain" "enforce" "disable" ];
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  options.curios.hardened.apparmor-profiles = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description =
        "Ship CuriOS AppArmor profiles. Requires curios.hardened.anssi.reinforced.enable and curios.hardened.anssi.reinforced.rule45 to be enabled.";
    };

    desktop = {
      browsers = {
        brave = {
          mode = mkOption {
            type = modeType;
            default = "enforce";
            description = "AppArmor profile mode for Brave.";
          };
        };
      };

      chat = {
        discord = {
          mode = mkOption {
            type = modeType;
            default = "enforce";
            description = "AppArmor profile mode for Discord.";
          };
        };
        signal-desktop = {
          mode = mkOption {
            type = modeType;
            default = "enforce";
            description = "AppArmor profile mode for Signal Desktop.";
          };
        };
      };

      gaming = {
        steam = {
          mode = mkOption {
            type = modeType;
            default = "complain";
            description = "AppArmor profile mode for Steam.";
          };
        };
      };

      office = {
        evince = {
          mode = mkOption {
            type = modeType;
            default = "enforce";
            description =
              "AppArmor profile mode for Evince (viewer, previewer, daemon, thumbnailer).";
          };
        };
        onlyoffice = {
          mode = mkOption {
            type = modeType;
            default = "enforce";
            description =
              "AppArmor profile mode for OnlyOffice desktop editors.";
          };
        };
      };
    };

    cli = {
      opencode = {
        mode = mkOption {
          type = modeType;
          default = "enforce";
          description =
            "AppArmor profile mode for OpenCode TUI (AI coding agent).";
        };
      };
    };
  };

  # dbus rules are enforced by the bus daemon, not by the kernel on the
  # session socket. Without this, peer=(name=...) denies are never consulted.
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    services.dbus.apparmor = "enabled";
  };
}
