# Create a desktop shortcut for Slack app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-slack";
  version="0.6";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-slack-icon.svg
      ./webapp-slack-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.slack.app";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://app.slack.com/client";
    desktopName = "Slack App";
    icon = "webapp-slack";
    categories = [ "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-slack-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-slack.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-slack-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-slack.svg
  '';
}