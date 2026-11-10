# Lanzaboote bootloader: Secure Boot + TPM2 measured boot via UKI (systemd-stub)
# Replaces Limine on the feature/tpm2 branch.
# Source: https://github.com/nix-community/lanzaboote

{ config, lib, pkgs, ... }:

let
  lanzaboote-src = builtins.fetchGit {
    url = "https://github.com/nix-community/lanzaboote.git";
    rev = "v0.4.2";
  };
in {
  imports = [ "${lanzaboote-src}/nixos" ];

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
        description = "Path to the PKI bundle for Secure Boot keys (must match sbctl keydir).";
      };
    };
  };

  config = lib.mkIf
    (config.curios.bootefi.enable && config.curios.bootefi.lanzaboote.enable) {
      boot = {
        lanzaboote = {
          enable = true;
          inherit (config.curios.bootefi.lanzaboote) pkiBundle;
          configurationLimit = 4;
        };

        # Lanzaboote replaces both systemd-boot and Limine
        loader = {
          systemd-boot.enable = lib.mkForce false;
          limine.enable = lib.mkForce false;
        };
      };

      # Note: sbctl is already installed by boot-efi.nix
    };
}
