# Create a desktop shortcut for Google gemini-cli package.
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="desktop-gemini";
  version="0.2";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./desktop-gemini-icon.svg
      ./desktop-gemini-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.google.gemini";
    exec = "/run/current-system/sw/bin/alacritty -e gemini";
    desktopName = "Gemini CLI";
    icon = "desktop-gemini";
    categories = [ "Science" "ArtificialIntelligence" ];
    terminal = true;
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp desktop-gemini-icon-48.png $out/share/icons/hicolor/48x48/apps/desktop-gemini.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp desktop-gemini-icon.svg $out/share/icons/hicolor/scalable/apps/desktop-gemini.svg
  '';
}