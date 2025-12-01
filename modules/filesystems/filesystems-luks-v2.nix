# LUKS + LVM filesystems
# As defined by 'curios-install' when crypt full disk option is activated.

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.filesystems.luks.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description =
        "Filesystems with LUKS + LVM as defined by 'curios-install' full disk encryption option.";
    };
  };

  config = lib.mkIf config.curios.filesystems.luks.enable {
    boot.initrd.kernelModules = [ "dm-snapshot" "cryptd" ];
    boot.initrd.luks.devices."cryptroot".device =
      "/dev/disk/by-label/curiosystem";

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
