# Split configurations files, see: https://nixos.wiki/wiki/NixOS_modules
# Imports every other configurations files from here.

{ pkgs, lib, ... }:
{
  imports = [
    ./boot-efi.nix
    ./cosmic.nix
    ./curios-options.nix
    ./curios-pkgs.nix
    ./desktop-apps/default.nix
    ./fonts.nix
    ./hardened/default.nix
    ./hardware/amd-gpu.nix
    ./hardware/laptop.nix
    ./hardware/nvidia-gpu.nix
    ./filesystems/filesystems-luks.nix
    ./filesystems/filesystems-mini.nix
    ./networking.nix
    ./platforms/amd64.nix
    ./platforms/rpi4.nix
    ./services.nix
    ./services-ai.nix
    ./virtualisation.nix
    ./zsh.nix
  ];
}
