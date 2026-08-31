# CuriOS-minimal ISO configuration file
# Basic installer for the console. Based on NixOS ${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix
# Provide an ISO with a minimal size (1.7Gib) but most pkgs will be downloaded
# from sources and compiled during installation.
# See: https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
# https://nixos.org/manual/nixos/stable/index.html#sec-building-image
# https://nixos.org/manual/nixpkgs/stable/#chap-stdenv

{ pkgs, modulesPath, ... }:
let
  curios-sources = pkgs.callPackage ../pkgs/curios-sources { };
  curios-dotfiles = pkgs.callPackage ../pkgs/curios-dotfiles { };
in {
  imports = [
    #"${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix"
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal-combined.nix"
  ];

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

