# Create a desktop shortcut for MS Teams web app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname = "webapp-teams";
  version = "0.2";

  src = lib.fileset.toSource {
    root = ./.;
    fileset =
      lib.fileset.unions [ ./webapp-teams-icon.svg ./webapp-teams-icon-48.png ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.microsoft.teams";
    exec =
      "/run/current-system/sw/bin/brave --new-window --app=https://teams.microsoft.com/";
    desktopName = "MS Teams webapp";
    icon = "webapp-teams";
    categories = [ "Chat" "Network" "Office" ];
  };
  installPhase = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy icon in correct folders
    mkdir -p $out/share/icons/hicolor/48x48/apps
    cp webapp-teams-icon-48.png $out/share/icons/hicolor/48x48/apps/webapp-teams.png
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp webapp-teams-icon.svg $out/share/icons/hicolor/scalable/apps/webapp-teams.svg
  '';
}

