{ pkgs ? import <nixpkgs> {} }:
#pkgs.callPackage ../pkgs/curios-dotfiles {}
#pkgs.callPackage ../pkgs/curios-manager {}
#pkgs.callPackage ../pkgs/curios-sources {}
pkgs.callPackage ../pkgs/curios-update {}

# test it locally with:
#nix-build && nix-env -i -f default.nix
# See:
#nix profile list
#nix-env --uninstall curios-sources-unstable