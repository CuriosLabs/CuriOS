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
      onlyoffice.desktopeditors.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "OnlyOffice Desktop Editors suite.";
      };
      thunderbird.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Mozilla Thunderbird email client.";
      };
      crm = {
        salesforce = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Salesforce CRM web app.";
          };
          baseUrl = lib.mkOption {
            type = lib.types.str;
            default = "your-domain.my.salesforce.com";
            description = "Your Salesforce 'My Domain' base URL.";
          };
        };
        hubspot = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "HubSpot CRM web app.";
          };
          baseUrl = lib.mkOption {
            type = lib.types.str;
            default = "app.hubspot.com";
            description = "HubSpot web app base URL.";
          };
        };
      };
      finance = {
        gnucash.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Free software for accounting.";
        };
      };
      projects = {
        basecamp = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Basecamp.com project management by 37signals.";
          };
          baseUrl = lib.mkOption {
            type = lib.types.str;
            default = "launchpad.37signals.com/signin";
            description = "Basecamp web app base URL.";
            example = "3.basecamp.com/0123456/";
          };
        };
        jira = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Atlassian Jira web-based project management.";
          };
          baseUrl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description =
              "Your Jira cloud custom domain like: mycompany.atlassian.net";
            example = "mycompanynamehere.atlassian.net";
          };
        };
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
    environment.systemPackages = [ pkgs.obsidian pkgs.joplin-desktop ]
      ++ lib.optionals config.curios.desktop.apps.office.libreoffice.enable
      [ pkgs.libreoffice ] ++ lib.optionals
      config.curios.desktop.apps.office.onlyoffice.desktopeditors.enable
      [ pkgs.onlyoffice-desktopeditors ]
      ++ lib.optionals config.curios.desktop.apps.office.thunderbird.enable
      [ pkgs.thunderbird ]
      ++ lib.optionals config.curios.desktop.apps.office.crm.salesforce.enable
      [ (import ./webapp-salesforce.nix { inherit config pkgs lib; }) ]
      ++ lib.optionals config.curios.desktop.apps.office.crm.hubspot.enable
      [ (import ./webapp-hubspot.nix { inherit config pkgs lib; }) ]
      ++ lib.optionals config.curios.desktop.apps.office.finance.gnucash.enable
      [ pkgs.gnucash ]
      ++ lib.optionals
      config.curios.desktop.apps.office.projects.basecamp.enable
      [ (import ./webapp-basecamp.nix { inherit config pkgs lib; }) ]
      ++ lib.optionals config.curios.desktop.apps.office.projects.jira.enable
      [ (import ./webapp-jira.nix { inherit config pkgs lib; }) ]
      ++ lib.optionals
      config.curios.desktop.apps.office.conferencing.slack.enable
      [ (import ./webapp-slack.nix) ] ++ lib.optionals
      config.curios.desktop.apps.office.conferencing.teams.enable
      [ (import ./webapp-teams.nix) ] ++ lib.optionals
      config.curios.desktop.apps.office.conferencing.zoom.enable
      [ pkgs.zoom-us ];
  };
}
