# Imports every other configurations files from here.
# webapp-*.nix and desktop-*.nix are imported in different nix files.

{ ... }:
{
  imports = [
    ./basics.nix
    ./crypto.nix
    ./devops.nix
    ./gaming.nix
    ./office.nix
    ./studio.nix
  ];
}
