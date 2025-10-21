# Create a desktop shortcut for ChatGTP.com app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-chatgpt";
  version="0.5";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-chatgpt-icon-256.png
      ./webapp-chatgpt-icon-128.png
      ./webapp-chatgpt-icon-64.png
      ./webapp-chatgpt-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.chatgpt";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://chatgpt.com/";
    desktopName = "ChatGPT App";
    icon = "webapp-chatgpt";
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
      cp webapp-chatgpt-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-chatgpt.png
    done
  '';
}