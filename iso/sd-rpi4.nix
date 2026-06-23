# CuriOS pre-installed SD card image for Raspberry Pi 4 (aarch64).
# Builds the final running CuriOS system as an SD image (no install step).
#
# Cross-built from x86_64 via binfmt/QEMU emulation:
#   nix-build '<nixpkgs/nixos>' --argstr system aarch64-linux \
#     -A config.system.build.sdImage -I nixos-config=./iso/sd-rpi4.nix
#
# Or via the justfile recipe:
#   just build-sd-rpi4
#
# Requires aarch64 binfmt emulation on the build host:
#   boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
# (CuriOS enables it via `curios.virtualisation.enable = true`.)
#
# Based on nixpkgs sd-image-aarch64.nix:
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image-aarch64.nix

{ pkgs, modulesPath, lib, ... }:

let
  # Custom CuriOS module settings for the RPi4 SD image.
  sdModules = builtins.fromJSON (builtins.readFile ./sd-rpi4-modules.json);
in {
  imports = [
    # Nixpkgs SD image builder (MBR + FAT32 firmware + ext4 root, auto-expand on first boot).
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    # All CuriOS modules.
    ../modules/default.nix
    # Custom user/network settings for the SD image.
    ./sd-rpi4-settings.nix
  ];

  # Inject CuriOS options from the custom modules.json.
  curios = sdModules.curios or { };

  # ZFS is heavy to build under QEMU emulation and irrelevant on RPi4.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # SD image filename base.
  image.baseName = "CuriOS";

  # Headless-friendly: allow SSH on first boot for remote setup.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  # CuriOS variant stamp.
  system.nixos.variant_id = "rpi4-sd";
}
