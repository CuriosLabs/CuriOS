# Create a desktop shortcut for Atlassian Jira cloud web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ config, pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-jira";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset =
      lib.fileset.unions [ ./webapp-jira-icon.svg ./webapp-jira-icon-48.png ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "net.atlassian.jira";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://${config.curios.desktop.apps.office.projects.jira.baseUrl}";
    desktopName = "Jira";
    icon = "webapp-jira";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-jira-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-jira.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-jira-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-jira.svg
  '';
}

