# Create a desktop shortcut for WhatsApp web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-whatsapp";
  version="0.6";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-whatsapp-icon.svg
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
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-whatsapp-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-whatsapp.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-whatsapp-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-whatsapp.svg
  '';
}