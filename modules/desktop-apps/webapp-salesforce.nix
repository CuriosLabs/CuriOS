# Create a desktop shortcut for Atlassian Jira web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ config, pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-salesforce";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-salesforce-icon.svg
      ./webapp-salesforce-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.salesforce";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://${config.curios.desktop.apps.office.crm.salesforce.baseUrl}";
    desktopName = "Salesforce";
    icon = "webapp-salesforce";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-salesforce-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-salesforce.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-salesforce-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-salesforce.svg
  '';
}

