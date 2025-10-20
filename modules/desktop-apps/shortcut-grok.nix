# Create a desktop shortcut for X.ai Grok app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="desktop-app-grok";
  version="0.3";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./shortcut-grok-icon-256.png
      ./shortcut-grok-icon-128.png
      ./shortcut-grok-icon-64.png
      ./shortcut-grok-icon-48.png
      ./shortcut-grok-icon-32.png
      ./shortcut-grok-icon-24.png
      ./shortcut-grok-icon-16.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.x.grok";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://x.ai/grok";
    desktopName = "Grok App";
    icon = "desktop-app-grok";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    icon_sizes=("16" "24" "32" "48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp shortcut-grok-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/desktop-app-grok.png
    done
  '';
}