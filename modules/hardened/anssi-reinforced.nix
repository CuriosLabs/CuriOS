# Linux hardened kernel rules as defined by [ANSSI](https://cyber.gouv.fr/).
# Reinforced level rules - should only be set on system with need of stronger security.
# See: https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.anssi.reinforced = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Reinforced hardening rules for a system with need of stronger security - MAY break things.";
      };
      rule7 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R7 - Activating the IOMMU";
      };
      rule10 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R10 - Disabling kernel modules loading";
      };
      rule39 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R39 - /etc/sudoers extra configuration (requiretty).";
      };
      rule45 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R45 - Activating AppArmor.";
      };
    };
  };

  config = lib.mkIf config.curios.anssi.reinforced.enable {
    boot = {
      kernelParams =
        lib.optionals config.curios.anssi.reinforced.rule7 [ "iommu=force" ];

      kernel.sysctl = lib.optionalAttrs config.curios.anssi.reinforced.rule10 {
        "kernel.modules_disabled" = 1;
      };
    };

    security = {
      apparmor = lib.mkIf config.curios.anssi.reinforced.rule45 {
        enable = true;
        enableCache = true;
        killUnconfinedConfinables = true;
      };

      lsm = lib.optionals config.curios.anssi.reinforced.rule45 [
        "capability"
        "landlock"
        "yama"
        "bpf"
        "apparmor"
      ];

      sudo = lib.mkIf config.curios.anssi.reinforced.rule39 {
        extraConfig = ''
          Defaults requiretty
        '';
      };
    };
  };
}
