# EFI boot options
# Note: if needed, re-create UEFI boot entry with:
# sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "CuriOS" --loader '\EFI\limine\BOOTX64.EFI'
# Find boot loader with:
# sudo fd -e efi . /boot/

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.bootefi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable EFI boot loader - REQUIRED on AMD64 platform.";
      };
      kernel.latest = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "Use latest stable kernel available if true, otherwise use LTS kernel. See: https://nixos.wiki/wiki/Linux_kernel";
      };
      limine = {
        enable = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "DEPRECATED";
        };
        resolution = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "1920x1080";
          description = "DEPRECATED";
        };
        secureBoot = {
          enable = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED";
          };
          firmware = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "DEPRECATED";
          };
        };
        wallpaper = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "DEPRECATED";
        };
      };
    };
  };

  config = lib.mkIf config.curios.bootefi.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      kernelPackages = if config.curios.bootefi.kernel.latest then
        lib.mkDefault pkgs.linuxPackages_latest
      else
        lib.mkDefault pkgs.linuxPackages;
      kernel.sysctl = {
        # Reduce the frequency of swapping data from RAM to swap space.
        "vm.swappiness" = 10;
        # Restart in case of Out of Memory
        "vm.panic_on_oom" = 1;
        # Restart after 10 seconds of panic
        "kernel.panic" = 10;
      };
      # NOTE: blacklisting esp4/esp6 disables IPsec (Libreswan/strongSwan/manual ip
      # xfrm). WireGuard and Tailscale are unaffected. Remove this if IPsec is needed.
      blacklistedKernelModules = [ "act_pedit" "esp4" "esp6" "rxrpc" ];
      #
      loader = {
        efi.canTouchEfiVariables = lib.mkDefault true;
        systemd-boot = {
          # systemd-boot is the fallback when Lanzaboote is not enabled
          enable = !config.curios.bootefi.lanzaboote.enable;
          # Limit the number of generations to keep
          configurationLimit = 4;
        };
      };
      tmp.cleanOnBoot = true;

      # Plymouth boot splash screen
      plymouth = {
        enable = true;
        theme = "pixels";
        themePackages = [
          (pkgs.adi1090x-plymouth-themes.override {
            selected_themes = [ "colorful_loop" "lone" "pixels" "rings" ];
          })
        ];
        #logo = "${pkgs.nixos-icons}/share/icons/hicolor/48x48/apps/nix-snowflake-white.png";
      };

      # Enable "Silent boot"
      consoleLogLevel = lib.mkDefault 3;
      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key
      # It will just not appear on screen unless a key is pressed
      #loader.timeout = 0;

      # Force disabling ZFS support (for unsupported latest kernel usage)
      supportedFilesystems = {
        btrfs = lib.mkForce false;
        zfs = lib.mkForce false;
      };

      # Remove ZFS warning during ISO build.
      zfs.forceImportRoot = lib.mkForce false;
    };

    environment.systemPackages = [
      # Provide tools with more details on EFI db and KEK - See `efi-readvar -v KEK`
      pkgs.efitools
      # Manage UEFI boot entries - See `efibootmgr -v`
      pkgs.efibootmgr
      # Provide secure boot key manager
      pkgs.sbctl
    ];
  };
}
