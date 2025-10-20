# Office suite desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps = {
      office.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "LibreOffice suite desktop apps.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.office.enable {
    environment.systemPackages = [
      pkgs.libreoffice
      (import ./shortcut-slack.nix)
    ];
  };
}