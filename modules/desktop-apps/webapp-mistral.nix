# Create a desktop shortcut for Mistral leChat app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-mistral";
  version="0.5";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-mistral-icon-256.png
      ./webapp-mistral-icon-128.png
      ./webapp-mistral-icon-64.png
      ./webapp-mistral-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.mistral.chat";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://chat.mistral.ai/chat";
    desktopName = "Mistral LeChat App";
    icon = "webapp-mistral";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    icon_sizes=("48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp webapp-mistral-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-mistral.png
    done
  '';
}