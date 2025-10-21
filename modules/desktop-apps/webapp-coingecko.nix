# Create a desktop shortcut for Coingecko BTC price app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-coingecko";
  version="0.5";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-coingecko-icon-256.png
      ./webapp-coingecko-icon-128.png
      ./webapp-coingecko-icon-64.png
      ./webapp-coingecko-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.coingecko.btc";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://www.coingecko.com/en/coins/bitcoin";
    desktopName = "Coingecko Bitcoin Price";
    icon = "webapp-coingecko";
    categories = [ "Finance" "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    icon_sizes=("48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp webapp-coingecko-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-coingecko.png
    done
  '';
}