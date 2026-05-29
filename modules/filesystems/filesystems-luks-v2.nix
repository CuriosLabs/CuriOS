# LUKS + LVM filesystems
# As defined by 'curios-install' when crypt full disk option is activated.

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.filesystems.luks.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Filesystems with LUKS+LVM - SET by curios-install";
    };
  };

  config = lib.mkIf config.curios.filesystems.luks.enable {
    boot.initrd.kernelModules = [ "dm-snapshot" "cryptd" ];

    # Note: curios.security.luksFido2.enable lives in security.nix (thematic grouping
    # with other YubiKey features), but the actual LUKS configuration must live here.
    boot.initrd.luks.devices."cryptroot" = lib.mkMerge [
      {
        device = "/dev/disk/by-label/curiosystem";
      }
      (lib.mkIf config.curios.security.luksFido2.enable {
        crypttabExtraOpts = [ "fido2-device=auto" ];
      })
    ];

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
    };

    swapDevices = [{ device = "/dev/disk/by-label/swap"; }];
  };
}
