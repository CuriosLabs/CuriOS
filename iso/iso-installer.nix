# CuriOS installer ISO. Console live image plus a prebuilt default CuriOS
# store closure so nixos-install can copy packages instead of compiling them.
# See: https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
# https://nixos.org/manual/nixos/stable/index.html#sec-building-image
# https://nixos.org/manual/nixpkgs/stable/#chap-stdenv

{ pkgs, modulesPath, ... }:
let
  curios-sources = pkgs.callPackage ../pkgs/curios-sources { };
  curios-dotfiles = pkgs.callPackage ../pkgs/curios-dotfiles { };
  seedSystem = (import "${pkgs.path}/nixos" {
    configuration = ./iso-seed.nix;
  }).config.system.build.toplevel;
in {
  imports = [
    #"${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-combined.nix"
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  # Default CuriOS closure (COSMIC, applet, Brave, …) for nixos-install to copy
  # from the live store instead of compiling on the target.
  isoImage.storeContents = [ seedSystem ];
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # Enabling or disabling modules:

  # Minimum packages for installation
  environment.systemPackages = [
    curios-sources
    curios-dotfiles
    pkgs.e2fsprogs
    pkgs.git
    pkgs.gum
    pkgs.gnused
    pkgs.jq
    pkgs.nano
    pkgs.parted
    pkgs.pciutils
    pkgs.terminaltexteffects
  ];

  boot.zfs.forceImportRoot = false;

  i18n.extraLocales = "all";
  console.font = "LatArCyrHeb-16";

  networking.hostName = "CuriOS";

  # Disable command-not-found to avoid conflict with minimal profile
  programs.command-not-found.enable = false;

  programs.bash.interactiveShellInit = ''
    echo "Launching CuriOS installer..."
    sleep 5
    sudo curios-install
  '';
}

