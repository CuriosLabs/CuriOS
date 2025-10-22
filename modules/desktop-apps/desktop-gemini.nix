# Create a desktop shortcut for Google gemini-cli package.
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="desktop-gemini";
  version="0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./desktop-gemini-icon-256.png
      ./desktop-gemini-icon-128.png
      ./desktop-gemini-icon-64.png
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
    icon_sizes=("48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp desktop-gemini-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/desktop-gemini.png
    done
  '';
}