# Create a desktop shortcut for WhatsApp web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-whatsapp";
  version="0.5";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-whatsapp-icon-256.png
      ./webapp-whatsapp-icon-128.png
      ./webapp-whatsapp-icon-64.png
      ./webapp-whatsapp-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.whatsapp.web";
    exec = "/run/current-system/sw/bin/brave --new-window --app=https://web.whatsapp.com/";
    desktopName = "WhatsApp webapp";
    icon = "webapp-whatsapp";
    categories = [ "Chat" "Network" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    icon_sizes=("48" "64" "128" "256")
    for icon in ''${icon_sizes[*]}
    do
      mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
      cp webapp-whatsapp-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-whatsapp.png
    done
  '';
}