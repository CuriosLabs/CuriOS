# Minimal LVM filesystems.
# As defined by 'curios-install'

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.filesystems.minimal.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Minimal LVM filesystems as defined by 'curios-install'.";
    };
  };

  config = lib.mkIf config.curios.filesystems.minimal.enable {
    boot.initrd.kernelModules = [ "dm-snapshot" ];

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

    swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
  };
}
