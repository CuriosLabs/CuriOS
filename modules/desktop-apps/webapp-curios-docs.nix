# Create a desktop shortcut for CuriOS documentation.
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html

{ pkgs, lib }:
pkgs.stdenv.mkDerivation rec {
  pname = "curios-documentation";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-curios-docs-icon.svg
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "dev.curioslabs.docs";
    exec = "xdg-open https://github.com/CuriosLabs/CuriOS/blob/master/docs/index.md";
    desktopName = "CuriOS Documentation";
    icon = "desktop-curios-docs";
    categories = [ "System" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-curios-docs-icon.svg $out/share/icons/hicolor/scalable/apps/desktop-curios-docs.svg
  '';
}
