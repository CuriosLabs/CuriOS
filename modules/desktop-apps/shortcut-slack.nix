# Create a desktop shortcut for Slack app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="desktop-app-slack";
  version="0.2";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./shortcut-slack-icon-256.png
      ./shortcut-slack-icon-128.png
      ./shortcut-slack-icon-64.png
      ./shortcut-slack-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.slack.app";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://app.slack.com/client";
    desktopName = "Slack App";
    icon = "desktop-app-slack";
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
      cp shortcut-slack-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/desktop-app-slack.png
    done
  '';
}