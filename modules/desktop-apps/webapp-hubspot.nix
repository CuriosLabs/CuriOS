# Create a desktop shortcut for HubSpot web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ config, pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-hubspot";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./webapp-hubspot-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.hubspot";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://${config.curios.desktop.apps.office.crm.hubspot.baseUrl}";
    desktopName = "HubSpot";
    icon = "webapp-hubspot";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folder
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-hubspot-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-hubspot.svg
  '';
}

