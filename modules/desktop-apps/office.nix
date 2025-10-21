# Office suite desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps = {
      office.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "LibreOffice suite desktop apps - Slack webapp.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.office.enable {
    environment.systemPackages = [
      pkgs.libreoffice
      (import ./webapp-slack.nix)
    ];
  };
}