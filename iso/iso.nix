# CuriOS ISO configuration file
# See: https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
# https://nixos.org/manual/nixos/stable/index.html#sec-building-image

{ pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    #"${modulesPath}/installer/cd-dvd/channel.nix"
    #./modules/default.nix
  ];

  # Minimum packages for installation
  environment.systemPackages = with pkgs; [
    nano
    disko
    parted
    git
  ];

  networking.hostName = "CuriOS";
}
