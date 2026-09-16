# Create a desktop shortcut for Microsoft 365 Excel web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-ms-excel";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./webapp-ms-excel-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "microsoft.cloud.excel";
    exec = "/run/current-system/sw/bin/xdg-open https://excel.cloud.microsoft/";
    desktopName = "Microsoft 365 Excel";
    icon = "webapp-ms-excel";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-ms-excel-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-ms-excel.svg
  '';
}
