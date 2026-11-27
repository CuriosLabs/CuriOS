# Create a desktop shortcut for opencode TUI app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "desktop-opencode";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./desktop-opencode-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.opencode";
    exec = "/run/current-system/sw/bin/xdg-terminal-exec opencode";
    desktopName = "OpenCode";
    icon = "desktop-opencode";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp desktop-opencode-icon.svg $out/share/icons/hicolor/scalable/apps/desktop-opencode.svg
  '';
}

