# EFI boot options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.bootefi.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable systemd EFI boot loader - REQUIRED on AMD64 platform.";
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
        if config.curios.bootefi.kernel.latest then pkgs.linuxPackages_latest else pkgs.linuxPackages;
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
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # Limit the number of generations to keep
        systemd-boot.configurationLimit = 5;
      };
      tmp.cleanOnBoot = true;

      # Plymouth boot splash screen
      # When LUKS FIDO2 is enabled we provide a variant theme with a more
      # accurate password prompt cue (instead of the generic "Enter Password").
      plymouth = {
        enable = true;
        theme = if config.curios.security.luksFido2.enable then "pixels-fido2" else "pixels";
        themePackages =
          let
            adiThemes = pkgs.adi1090x-plymouth-themes.override {
              selected_themes = [
                "colorful_loop"
                "lone"
                "pixels"
                "rings"
              ];
            };
            fido2PixelsTheme = pkgs.runCommand "curios-plymouth-pixels-fido2" { } ''
              mkdir -p $out/share/plymouth/themes/pixels-fido2
              cp -r ${
                pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "pixels" ]; }
              }/share/plymouth/themes/pixels/. $out/share/plymouth/themes/pixels-fido2/

              # Adjust metadata and script filename for the new theme name
              mv $out/share/plymouth/themes/pixels-fido2/pixels.plymouth $out/share/plymouth/themes/pixels-fido2/pixels-fido2.plymouth
              substituteInPlace $out/share/plymouth/themes/pixels-fido2/pixels-fido2.plymouth \
                --replace-fail 'Name=pixels' 'Name=pixels-fido2' \
                --replace-fail 'pixels.script' 'pixels-fido2.script'

              mv $out/share/plymouth/themes/pixels-fido2/pixels.script $out/share/plymouth/themes/pixels-fido2/pixels-fido2.script

              # Use a context-aware prompt when FIDO2 disk unlock is active.
              # This addresses confusion during boot: users see a YubiKey PIN prompt
              # but the default theme always said "Enter Password".
              substituteInPlace $out/share/plymouth/themes/pixels-fido2/pixels-fido2.script \
                --replace-fail 'Image.Text("Enter Password", 1, 1, 1);' \
                               'Image.Text("Key PIN or recovery passphrase", 1, 1, 1);'
            '';
          in
          [ adiThemes ] ++ lib.optionals config.curios.security.luksFido2.enable [ fido2PixelsTheme ];
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
    };
  };
}
