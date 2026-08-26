# Default CuriOS system evaluated at ISO build time.
# Its closure is copied into the installer squashfs so nixos-install can
# reuse store paths instead of compiling (e.g. curios-manager-applet).

{ lib, ... }: {
  imports = [ ../configuration.nix ];

  system.copySystemConfiguration = lib.mkForce false;
}
