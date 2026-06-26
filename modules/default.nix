# Split configurations files, see: https://nixos.wiki/wiki/NixOS_modules
# Imports every other configurations files from here.

{ ... }: {
  imports = [
    ./backup.nix
    ./boot-efi.nix
    ./cosmic.nix
    ./curios-pkgs.nix
    ./desktop-apps/default.nix
    ./fonts.nix
    ./hardened/default.nix
    ./hardware/default.nix
    ./filesystems/filesystems-luks-v2.nix
    ./filesystems/filesystems-mini-v2.nix
    ./networking.nix
    ./others.nix
    ./platforms/default.nix
    ./services.nix
    ./security.nix
    ./system.nix
    ./virtualisation.nix
    ./zsh.nix
  ];
}
