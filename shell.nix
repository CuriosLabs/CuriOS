{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # For curios-install
    dialog
    git
    mkpasswd
    parted
    # For justfile
    statix
    shellcheck
    fd
    just
    git
    gh
  ];
}
