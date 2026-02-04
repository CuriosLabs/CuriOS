{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # For Raspberry PI curios-install
    dialog
    git
    mkpasswd
    raspberrypi-eeprom
  ];
}
