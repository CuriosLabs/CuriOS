{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # For curios-install
    git
    gum
    jq
    mkpasswd
    parted
    terminaltexteffects
    # For justfile
    statix
    shellcheck
    fd
    just
    git
    gh
  ];
}
