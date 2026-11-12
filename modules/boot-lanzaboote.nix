# Lanzaboote bootloader: Secure Boot + TPM2 measured boot via UKI (systemd-stub)
# Replaces Limine on the feature/tpm2 branch.
# Source: https://github.com/nix-community/lanzaboote
# Useful commands:
# sbctl status
# sudo bootctl status
# efi-readvar -v PK
# efi-readvar -v KEK
# efi-readvar -v db
# efi-readvar -v dbx
# tpm2_pcrread
# systemd-analyze pcrs
# /run/current-system/systemd/lib/systemd/systemd-pcrlock is-supported
# ls -la /var/lib/systemd/pcrlock.json

{ config, lib, pkgs, ... }:

let
  lanzaboote-src = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/lanzaboote/archive/refs/tags/v1.2.0.tar.gz";
    sha256 = "0syvqpi77ia1vd189658g53mqjgw7i39zym2r0g7asdjkrz0mgmj";
  };
  # Import lanzaboote's default.nix which exposes nixosModules and packages (lzbt)
  lanzaboote = import "${lanzaboote-src}/default.nix" { };
in {
  imports = [ lanzaboote.nixosModules.lanzaboote ];

  options = {
    curios.bootefi.lanzaboote = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true; # Default on feature/tpm2 branch
        description =
          "Enable Lanzaboote bootloader (Secure Boot + TPM2 measured boot via UKI).";
      };
      pkiBundle = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/sbctl"; # sbctl default key directory
        description =
          "Path to the PKI bundle for Secure Boot keys (must match sbctl keydir).";
      };
      includeFirmwareBuiltinKeys = lib.mkOption {
        type = lib.types.bool;
        default = false; # OVMF/QEMU has none; enable on real hardware if needed
        description = ''
          Enroll firmware built-in keys (dbDefault/KEKDefault/PKDefault) alongside
          generated keys. Required on some hardware; not available on OVMF/QEMU.
        '';
      };
      includeMicrosoftKeys = lib.mkOption {
        type = lib.types.bool;
        default =
          true; # Required for EAC v2 (Microsoft UEFI CA is the only publicly trusted one)
        description = ''
          Enroll Microsoft keys. Required for EAC v2 compatibility and Windows dual-boot.
        '';
      };
    };
  };

  config = lib.mkIf
    (config.curios.bootefi.enable && config.curios.bootefi.lanzaboote.enable) {
      boot = {
        lanzaboote = {
          enable = true;
          # Allow unsigned install during nixos-install (keys don't exist yet).
          # Keys will be generated and enrolled on first boot.
          allowUnsigned = builtins.pathExists "/mnt/etc/nixos";
          autoGenerateKeys.enable = true;
          autoEnrollKeys = {
            enable = true;
            autoReboot = true; # Reboot to enroll keys in firmware
            includeFirmwareBuiltinKeys =
              config.curios.bootefi.lanzaboote.includeFirmwareBuiltinKeys;
            includeMicrosoftKeys =
              config.curios.bootefi.lanzaboote.includeMicrosoftKeys;
          };
          inherit (config.curios.bootefi.lanzaboote) pkiBundle;
          configurationLimit = 4;
          measuredBoot = {
            enable = true;
            # PCR 0 = firmware code, 4 = bootloader, 7 = Secure Boot state
            # PCR 1,2,3 may be flaky on some hardware
            pcrs = [ 0 4 7 ];
          };
          # Provide lzbt package from lanzaboote sources (no overlay in v1.2.0)
          package = lanzaboote.packages.lzbt;
        };

        # Lanzaboote replaces both systemd-boot and Limine
        loader = {
          systemd-boot.enable = lib.mkForce false;
          limine.enable = lib.mkForce false;
        };
      };

      # fwupd for updating UEFI db with latest Microsoft certificates (real hardware).
      # On OVMF/QEMU this is a no-op (no real firmware), but useful on bare metal.
      # Usage: sudo fwupdmgr refresh && sudo fwupdmgr update
      environment.systemPackages = [ pkgs.fwupd ];
    };
}
