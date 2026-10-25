# Linux hardened kernel rules as defined by [ANSSI](https://cyber.gouv.fr/).
# Reinforced level rules - should only be set on system with need of stronger security.
# See: https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

{ config, lib, ... }:
let
  # Detect CPU vendor to set the correct IOMMU parameter
  cpuVendor = if config.hardware.cpu.amd.updateMicrocode or false then
    "amd"
  else if config.hardware.cpu.intel.updateMicrocode or false then
    "intel"
  else
    "auto"; # Unknown vendor, fallback to both parameters
in {
  # Declare options
  options = {
    curios.hardened.anssi.reinforced = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Reinforced hardening rules for a system with need of stronger security - MAY break things.";
      };
      rule7 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R7 - Activating the IOMMU and VFIO modules.";
      };
      rule10 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R10 - Disabling kernel modules loading";
      };
      rule39 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "R39 - /etc/sudoers extra configuration (noexec, requiretty). WILL break a lot of SUDO commands.";
      };
      rule45 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R45 - Activating AppArmor.";
      };
    };
  };

  config = lib.mkIf config.curios.hardened.anssi.reinforced.enable {
    boot = {
      # R7 - IOMMU activation with VFIO support for PCI passthrough
      kernelParams = lib.optionals config.curios.hardened.anssi.reinforced.rule7
        (if cpuVendor == "amd" then
          [ "amd_iommu=on" ]
        else if cpuVendor == "intel" then
          [ "intel_iommu=on" ]
        else [
          "amd_iommu=on"
          "intel_iommu=on"
        ] # Fallback: unknown CPU, set both
        );

      # Load VFIO modules early (before GPU drivers) for PCI passthrough
      kernelModules =
        lib.optionals config.curios.hardened.anssi.reinforced.rule7 [
          "vfio"
          "vfio_iommu_type1"
          "vfio_pci"
        ];

      # Also load VFIO in initrd for early binding of GPU drivers
      initrd.kernelModules =
        lib.optionals config.curios.hardened.anssi.reinforced.rule7 [
          "vfio"
          "vfio_iommu_type1"
          "vfio_pci"
        ];

      kernel.sysctl =
        lib.optionalAttrs config.curios.hardened.anssi.reinforced.rule10 {
          "kernel.modules_disabled" = 1;
        };
    };

    security = {
      apparmor = {
        enable = lib.mkDefault config.curios.hardened.anssi.reinforced.rule45;
        enableCache = true;
        killUnconfinedConfinables = true;
      };

      auditd.enable = config.curios.hardened.anssi.reinforced.rule45;

      audit = {
        enable = config.curios.hardened.anssi.reinforced.rule45;
        rules = [
          "-a exit,always -F arch=b64 -S execve -F auid>=1000 -F auid!=-1 -k audit_watch_apparmor"
        ];
      };

      sudo = lib.mkIf config.curios.hardened.anssi.reinforced.rule39 {
        extraConfig = "Defaults noexec,requiretty";
      };
    };
  };
}
