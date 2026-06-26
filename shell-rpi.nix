{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # For Raspberry PI curios-install
    git
    gum
    jq
    mkpasswd
    raspberrypi-eeprom
    terminaltexteffects
  ];
}
