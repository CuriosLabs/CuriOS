# Create a desktop shortcut for 37signals basecamp.com web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ config, pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "webapp-basecamp";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-basecamp-icon-48.png
      ./webapp-basecamp-icon-64.png
      ./webapp-basecamp-icon-128.png
      ./webapp-basecamp-icon-256.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.basecamp";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://${config.curios.desktop.apps.office.projects.basecamp.baseUrl}";
    desktopName = "Basecamp";
    icon = "webapp-basecamp";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    icon_sizes=("48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp webapp-basecamp-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-basecamp.png
    done
  '';
}

