# Linux hardened kernel rules as defined by [ANSSI](https://cyber.gouv.fr/).
# Minimal level rules - should be set on every system.
# See: https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.hardened.anssi.minimal = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "Minimal hardening rules for a Linux system as recommended by ANSSI.";
      };
      rule5 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "R5 - Disable the bootloader editor";
      };
    };
  };

  config = lib.mkIf config.curios.hardened.anssi.minimal.enable {
    # systemd-boot EFI boot loader settings.
    boot.loader = {
      systemd-boot = {
        editor =
          if config.curios.hardened.anssi.minimal.rule5 then false else true;
      };
    };
  };
}
