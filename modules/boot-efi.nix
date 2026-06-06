# EFI boot options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.bootefi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "Enable EFI boot loader - REQUIRED on AMD64 platform.";
      };
      kernel.latest = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "Use latest stable kernel available if true, otherwise use LTS kernel. See: https://nixos.wiki/wiki/Linux_kernel";
      };
      limine = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description =
            "Enable Limine bootloader / boot manager. If false, systemd-boot will be used.";
        };
      };
    };
  };

  config = lib.mkIf config.curios.bootefi.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      kernelPackages = if config.curios.bootefi.kernel.latest then
        pkgs.linuxPackages_latest
      else
        pkgs.linuxPackages;
      initrd.systemd.enable = true;
      kernel.sysctl = {
        # Reduce the frequency of swapping data from RAM to swap space.
        "vm.swappiness" = 10;
        # Restart in case of Out of Memory
        "vm.panic_on_oom" = 1;
        # Restart after 10 seconds of panic
        "kernel.panic" = 10;
      };
      # Protection against CVE-2026-31431 if kernel < 6.12.85; 6.18.22; 6.19.12 or 7.0
      # Obsolete: pkgs.linuxPackages_latest and pkgs.linuxPackages have been updated.
      #kernelParams = lib.optionals (!config.curios.bootefi.kernel.latest)
      #  [ "modprobe.blacklist=algif_aead" ];
      #
      loader = {
        efi.canTouchEfiVariables = true;
        limine = {
          enable = lib.mkDefault config.curios.bootefi.limine.enable;
          maxGenerations = 5;
        };
        systemd-boot = {
          enable = !config.curios.bootefi.limine.enable;
          # Limit the number of generations to keep
          configurationLimit = 5;
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

      # Remove ZFS warning during ISO build.
      zfs.forceImportRoot = lib.mkForce false;
    };

    environment.systemPackages = [
      # Provide tools with more details on EFI db and KEK - See `efi-readvar -v KEK`
      pkgs.efitools
      # Provide secure boot key manager
      pkgs.sbctl
    ];
  };
}
