# Create a desktop shortcut for Claude.ai app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "webapp-claude";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-claude-icon.svg
      ./webapp-claude-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.claude.chats";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://claude.ai/chats";
    desktopName = "Claude";
    icon = "webapp-claude";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-claude-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-claude.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-claude-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-claude.svg
  '';
}

