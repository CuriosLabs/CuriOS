# EFI boot options

{ config, lib, pkgs, ... }:
{
  # Declare options
  options = {
    curios.bootefi.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable systemd EFI boot loader";
    };
    curios.bootefi.kernel.latest = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use latest stable kernel available if true, otherwise use LTS kernel. See: https://nixos.wiki/wiki/Linux_kernel";
    };
  };

  config = lib.mkIf config.curios.bootefi.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      kernelPackages =
        if config.curios.bootefi.kernel.latest then
          pkgs.linuxPackages_latest
        else
          pkgs.linuxPackages
        ;
      initrd.systemd.enable = true;
      kernel.sysctl = {
        "vm.swappiness" = 10; # Reduce the frequency of swapping data from RAM to swap space.
      };
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 5; # Limit the number of generations to keep
      };
      tmp.cleanOnBoot = true;

      # Plymouth boot splash screen
      plymouth = {
        enable = true;
        theme = "breeze";
        #logo = "${pkgs.nixos-icons}/share/icons/hicolor/48x48/apps/nix-snowflake-white.png";
      };

      # Enable "Silent boot"
      consoleLogLevel = 3;
      initrd.verbose = false;
      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key
      # It will just not appear on screen unless a key is pressed
      #loader.timeout = 0;

      # Force disabling ZFS support (for unsupported latest kernel usage)
      supportedFilesystems = {
        btrfs = lib.mkForce false;
        zfs = lib.mkForce false;
      };
    };
  };
}
