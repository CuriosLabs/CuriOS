# EFI boot options

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
        description = "Use latest stable kernel available if true, otherwise use LTS kernel. See: https://nixos.wiki/wiki/Linux_kernel";
      };
      limine = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Limine bootloader / boot manager. If false, systemd-boot will be used.";
        };
        secureBoot = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Secure Boot with Limine. See curios-manager -> security menu";
          };
          firmware = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enroll firmware built-in keys alongside Microsoft keys during Secure Boot key enrollment.";
          };
        };
        wallpaper = lib.mkOption {
          type = lib.types.path;
          default = pkgs.nixos-artwork.wallpapers.simple-dark-gray-bootloader.gnomeFilePath;
          description = "Wallpaper for the Limine boot menu.";
        };
      };
    };
  };

  config = lib.mkIf config.curios.bootefi.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      kernelPackages =
        if config.curios.bootefi.kernel.latest then
          lib.mkDefault pkgs.linuxPackages_latest
        else
          lib.mkDefault pkgs.linuxPackages;
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
      # Protection against CVE-2026-46331 (pedit COW) and CVE-2026-43503 (DirtyClone)
      # if kernel < 7.1-rc7. Both exploits use unprivileged userns + CAP_NET_ADMIN to
      # reach act_pedit (pedit COW) or esp4/esp6 + rxrpc (DirtyClone) and poison the
      # page cache backing setuid binaries. Blacklisting these modules breaks the
      # exploit chain at the module layer without disabling unprivileged user
      # namespaces (preserving Brave/Chromium sandbox and Flatpak portals).
      # Only needed on the LTS kernel (< 7.1); pkgs.linuxPackages_latest is 7.1.1 and
      # ships the full DirtyFrag patch chain (CVE-2026-31431, CVE-2026-43284,
      # CVE-2026-43500, CVE-2026-46300, CVE-2026-43503).
      # Obsolete once pkgs.linuxPackages (LTS) ships a kernel >= 7.1.
      # NOTE: blacklisting esp4/esp6 disables IPsec (Libreswan/strongSwan/manual ip
      # xfrm). WireGuard and Tailscale are unaffected. Remove this if IPsec is needed.
      blacklistedKernelModules = lib.optionals (!config.curios.bootefi.kernel.latest) [
        "act_pedit"
        "esp4"
        "esp6"
        "rxrpc"
      ];
      #
      loader = {
        efi.canTouchEfiVariables = lib.mkDefault true;
        limine = {
          enable = lib.mkDefault config.curios.bootefi.limine.enable;
          maxGenerations = 5;
          #style.wallpapers = [ config.curios.bootefi.limine.wallpaper ];
          # Secure Boot options
          secureBoot = {
            enable = lib.mkDefault config.curios.bootefi.limine.secureBoot.enable;
            inherit (pkgs) sbctl;
            autoEnrollKeys = {
              enable = lib.mkDefault config.curios.bootefi.limine.secureBoot.enable;
              extraArgs = [
                "--microsoft"
              ]
              ++ lib.optionals config.curios.bootefi.limine.secureBoot.firmware [ "--firmware-builtin" ];
            };
            autoGenerateKeys = lib.mkDefault config.curios.bootefi.limine.secureBoot.enable;
          };
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
