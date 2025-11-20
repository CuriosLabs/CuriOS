# Office suite desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps.office = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Default office desktop apps - Obsidian.";
      };
      libreoffice.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "LibreOffice suite desktop apps.";
      };
      conferencing = {
        slack.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Slack webapp.";
        };
        teams.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "MS Teams webapp.";
        };
        zoom.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Zoom.us video conference app.";
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.office.enable {
    environment.systemPackages = [
      pkgs.obsidian
    ]
    ++ lib.optionals config.curios.desktop.apps.office.libreoffice.enable [
      pkgs.libreoffice
    ]
    ++ lib.optionals config.curios.desktop.apps.office.conferencing.slack.enable [
      (import ./webapp-slack.nix)
    ]
    ++ lib.optionals config.curios.desktop.apps.office.conferencing.teams.enable [
      (import ./webapp-teams.nix)
    ]
    ++ lib.optionals config.curios.desktop.apps.office.conferencing.zoom.enable [
      pkgs.zoom-us
    ];
  };
}
