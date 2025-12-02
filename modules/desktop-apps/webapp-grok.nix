# Create a desktop shortcut for X.ai Grok app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "webapp-grok";
  version = "0.6";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-grok-icon-256.png
      ./webapp-grok-icon-128.png
      ./webapp-grok-icon-64.png
      ./webapp-grok-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.x.grok";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://x.ai/grok";
    desktopName = "Grok";
    icon = "webapp-grok";
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
      cp webapp-grok-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-grok.png
    done
  '';
}

