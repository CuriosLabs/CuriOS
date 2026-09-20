# Create a desktop shortcut for Microsoft 365 Word web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-ms-word";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./webapp-ms-word-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "microsoft.cloud.word";
    exec = "/run/current-system/sw/bin/xdg-open https://word.cloud.microsoft/";
    desktopName = "Microsoft 365 Word";
    icon = "webapp-ms-word";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-ms-word-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-ms-word.svg
  '';
}
