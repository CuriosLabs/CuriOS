# Split configurations files, see: https://nixos.wiki/wiki/NixOS_modules
# Imports every other configurations files from here.

{ config, lib, ... }: {
  imports = [
    ./curios-platforms.nix
    ./backup.nix
    ./boot-efi.nix
    ./cosmic.nix
    ./curios-pkgs.nix
    ./desktop-apps/default.nix
    ./fonts.nix
    ./hardened/default.nix
    ./hardware/amd-gpu.nix
    ./hardware/intel-gpu.nix
    ./hardware/laptop.nix
    ./hardware/nvidia-gpu.nix
    ./filesystems/filesystems-luks-v2.nix
    ./filesystems/filesystems-mini-v2.nix
    ./networking.nix
    ./others.nix
    ./platforms/amd64.nix
    ./services.nix
    ./security.nix
    ./system.nix
    ./virtualisation.nix
    ./zsh.nix
  ] ++ lib.optionals config.curios.platform.rpi4.enable [ ./platforms/rpi4.nix ]
    ++ lib.optionals config.curios.platform.rpi5.enable [ ./platforms/rpi5.nix ];
}
