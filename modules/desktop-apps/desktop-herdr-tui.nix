# Create a desktop shortcut for herdr TUI app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "desktop-herdr-tui";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./desktop-herdr-tui-icon.svg ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "dev.herdr.tui";
    exec = "/run/current-system/sw/bin/xdg-terminal-exec herdr";
    desktopName = "Herdr TUI";
    icon = "desktop-herdr-tui";
    categories = [ "Development" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp desktop-herdr-tui-icon.svg $out/share/icons/hicolor/scalable/apps/desktop-herdr-tui.svg
  '';
}
