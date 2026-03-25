# system options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.system = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED - Enable CuriOS system options.";
      };
      ansible.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Ansible automation tool.";
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "CuriOS";
        description = "Set system networking hostname.";
      };
      i18n.locale = lib.mkOption {
        type = lib.types.str;
        default = "en_US.UTF-8";
        description = "Set system i18n locale settings.";
      };
      keyboard = lib.mkOption {
        type = with lib.types; either str path;
        default = "us";
        description = "Set system keyboard map settings.";
      };
      pkgs = {
        autoupgrade.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automated packages update and cleanup.";
        };
        gc.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automated packages garbage collect.";
        };
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "Etc/GMT";
        description = ''
          Set system time zone. See <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>
                      for a comprehensive list of possible values for this setting.'';
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.system.enable {
    networking.hostName = lib.mkDefault config.curios.system.hostname;
    time.timeZone = lib.mkDefault config.curios.system.timeZone;
    i18n.defaultLocale = lib.mkDefault config.curios.system.i18n.locale;

    # Keyboard settings
    console.keyMap = lib.mkDefault config.curios.system.keyboard;

    system.autoUpgrade = {
      enable = lib.mkDefault config.curios.system.pkgs.autoupgrade.enable;
      dates = "03:40";
      randomizedDelaySec = "3min";
      # Reboot on new kernel, initrd or kernel module.
      allowReboot = false;
    };

    # Automatic collect garbage
    nix.gc = {
      automatic = lib.mkDefault config.curios.system.pkgs.gc.enable;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    environment.systemPackages =
      lib.optionals config.curios.system.ansible.enable [ pkgs.ansible ];
  };
}
