# Create a desktop shortcut for Odoo web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ config, pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-odoo";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./webapp-odoo-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.odoo";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://${config.curios.desktop.office.erp.odoo.baseUrl}";
    desktopName = "Odoo";
    icon = "webapp-odoo";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-odoo-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-odoo.svg
  '';
}

