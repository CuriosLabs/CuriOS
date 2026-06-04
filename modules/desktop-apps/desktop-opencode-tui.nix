# Create a desktop shortcut for opencode TUI app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "desktop-opencode-tui";
  version = "0.2";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./desktop-opencode-tui-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "ai.opencode.tui";
    exec = "/run/current-system/sw/bin/xdg-terminal-exec opencode";
    desktopName = "OpenCode TUI";
    icon = "desktop-opencode-tui";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp desktop-opencode-tui-icon.svg $out/share/icons/hicolor/scalable/apps/desktop-opencode-tui.svg
  '';
}

