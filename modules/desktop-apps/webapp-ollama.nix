# Create a desktop shortcut for Ollama local Open-WebUI app
# See https://specifications.freedesktop.org/menu-spec/1.0/category-registry.html
with import <nixpkgs> { };
stdenv.mkDerivation rec {
  pname="webapp-ollama-ui";
  version="0.5";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./webapp-ollama-icon-256.png
      ./webapp-ollama-icon-128.png
      ./webapp-ollama-icon-64.png
      ./webapp-ollama-icon-48.png
    ];
  };

  dontBuild = true;
  dontConfigure = true;
  desktopItem = pkgs.makeDesktopItem {
    name = "com.ollama.openwebui";
    exec = "/run/current-system/sw/bin/brave --new-window --app=http://localhost:8080/";
    desktopName = "Ollama Open-WebUI (local)";
    icon = "webapp-ollama-ui";
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
      cp webapp-ollama-icon-$icon.png $out/share/icons/hicolor/$icon\x$icon/apps/webapp-ollama-ui.png
    done
  '';
}