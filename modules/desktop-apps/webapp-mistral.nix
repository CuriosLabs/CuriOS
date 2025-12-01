# Create a desktop shortcut for Mistral leChat app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "webapp-mistral";
  version = "0.9";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-mistral-icon.svg
      ./webapp-mistral-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.mistral.chat";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://chat.mistral.ai/chat";
    desktopName = "Mistral LeChat";
    icon = "webapp-mistral";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-mistral-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-mistral.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-mistral-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-mistral.svg
  '';
}

