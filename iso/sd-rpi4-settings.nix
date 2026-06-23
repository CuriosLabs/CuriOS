# Custom settings for the CuriOS RPi4 pre-installed SD image.
# Minimal headless-friendly config: a default user with a simple password
# that can be changed with `passwd` on first boot.
#
# Users can edit this file before building to customize the image.

{ config, lib, pkgs, ... }:

{
  ### NixOS packages
  environment.systemPackages = [
    # Add extra packages here - find package name at https://search.nixos.org/packages
  ];

  ### User settings
  users = {
    mutableUsers = true;
    # Create plugdev group to access some USB devices without root privileges.
    extraGroups.plugdev = { };
    # Primary group for the default user.
    groups = { curios = { gid = 1000; }; };
    # Default user account.
    # Login: curios / curios — CHANGE THE PASSWORD on first boot with `passwd`!
    users.curios = {
      isNormalUser = true;
      initialPassword = "curios";
      description = "CuriOS User";
      group = "curios";
      extraGroups =
        [ "users" "wheel" "audio" "sound" "video" "plugdev" "dialout" ]
        ++ lib.optionals config.curios.networking.enable [ "networkmanager" ];
      uid = 1000;
      useDefaultShell = true;
      # Set your SSH pubkey here for passwordless headless login:
      #openssh.authorizedKeys.keys = [ "ssh-ed25519 XXXXXXX me@me.com" ];
    };
  };

  ### Networking
  networking = {
    nameservers = [ "9.9.9.9" "1.1.1.1" "2620:fe::fe" "2620:fe::9" ];
    useDHCP = lib.mkDefault true;
    firewall.enable = lib.mkDefault true;
  };

  # First NixOS release installed on this image. Do NOT change after install.
  system.stateVersion = "26.05";
}
