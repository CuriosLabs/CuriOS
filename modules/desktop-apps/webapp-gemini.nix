# Create a desktop shortcut for gemini.google.com webapp
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "webapp-gemini";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-gemini-icon.svg
      ./webapp-gemini-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.google.gemini";
    exec = "/run/current-system/sw/bin/xdg-open https://gemini.google.com/app";
    desktopName = "Gemini";
    icon = "webapp-gemini";
    categories = [ "Science" "ArtificialIntelligence" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-gemini-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-gemini.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-gemini-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-gemini.svg
  '';
}
