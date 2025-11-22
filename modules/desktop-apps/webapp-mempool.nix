# Create a desktop shortcut for mempool.space
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-mempool";
  version="0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-mempool-icon-256.png
      ./webapp-mempool-icon-128.png
      ./webapp-mempool-icon-64.png
      ./webapp-mempool-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "space.mempool";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://mempool.space/mempool-block/0";
    desktopName = "Bitcoin blockchain mempool";
    icon = "webapp-mempool";
    categories = [ "Finance" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    icon_sizes=("48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp webapp-mempool-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-mempool.png
    done
  '';
}
