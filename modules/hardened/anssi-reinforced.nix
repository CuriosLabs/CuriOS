# Linux hardened kernel rules as defined by [ANSSI](https://cyber.gouv.fr/).
# Reinforced level rules - should only be set on system with need of stronger security.
# See: https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.hardened.anssi.reinforced = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Reinforced hardening rules for a system with need of stronger security - MAY break things.";
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
        description = "R39 - /etc/sudoers extra configuration (noexec, requiretty). WILL break a lot of SUDO commands.";
      };
      rule45 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R45 - Activating AppArmor.";
      };
      ruleUsernsRestrict = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Custom rule - Restrict unprivileged user namespaces via AppArmor. Requires R45 (AppArmor) to be enabled and kernel >= 7.1.";
      };
    };
  };

  config = lib.mkIf config.curios.hardened.anssi.reinforced.enable {
    boot = {
      kernelParams = lib.optionals config.curios.hardened.anssi.reinforced.rule7 [ "iommu=force" ];

      kernel.sysctl = lib.mkMerge [
        (lib.optionalAttrs config.curios.hardened.anssi.reinforced.rule10 {
          "kernel.modules_disabled" = 1;
        })
        (lib.optionalAttrs
          (
            config.curios.hardened.anssi.reinforced.rule45
            && config.curios.hardened.anssi.reinforced.ruleUsernsRestrict
          )
          {
            "kernel.apparmor_restrict_unprivileged_userns" = 1;
            "kernel.apparmor_restrict_unprivileged_unconfined" = 1;
          }
        )
      ];
    };

    security = {
      apparmor = lib.mkIf config.curios.hardened.anssi.reinforced.rule45 {
        enable = true;
        enableCache = true;
        killUnconfinedConfinables = true;
      };

      sudo = lib.mkIf config.curios.hardened.anssi.reinforced.rule39 {
        extraConfig = "Defaults noexec,requiretty";
      };
    };
  };
}
