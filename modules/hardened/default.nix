# Imports every other configurations files from here.

{ ... }:
{
  imports = [
    ./accounts-daemon.nix
    ./acpid.nix
    ./cups.nix
    ./dbus.nix
    ./display-manager.nix
    ./docker.nix
    ./getty.nix
    ./NetworkManager.nix
    ./NetworkManager-dispatcher.nix
    ./nix-daemon.nix
    ./nscd.nix
    ./rescue.nix
    ./rtkit.nix
    ./sshd.nix
    ./user.nix
    ./wpa_supplicant.nix
  ];
}
