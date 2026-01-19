# Install lm-studio from the AppImage published on the official website.
# See: https://lmstudio.ai/download
# See: https://wiki.nixos.org/wiki/Appimage

{ pkgs, lib }:
let
  pname = "lm-studio";
  version = "0.3.39-2";

  src = pkgs.fetchurl {
    url =
      "https://installers.lmstudio.ai/linux/x64/${version}/LM-Studio-${version}-x64.AppImage";
    hash = "sha256-I+dO/tC6SALjr8YryVgXfI7e6e35y7CkUHsHeBcWE5w=";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
  downloadToTemp = true;

  desktopItem = pkgs.makeDesktopItem {
    name = "ai.lmstudio";
    exec = "/run/current-system/sw/bin/lm-studio";
    desktopName = "LM Studio local AI";
    icon = "lmstudio";
    categories = [ "Science" "ArtificialIntelligence" ];
    terminal = false;
    type = "Application";
  };
in pkgs.appimageTools.wrapType2 {
  inherit pname version pkgs src;

  nativeBuildInputs = [ pkgs.imagemagick ];

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy and resize icon in correct folders
    for size in 48 64 128 256; do
      mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
      convert -background none -resize "$size"x"$size" ${appimageContents}/lm-studio.png $out/share/icons/hicolor/"$size"x"$size"/apps/lmstudio.png
    done
  '';

  meta = {
    description = "LM Studio";
    homepage = "https://lmstudio.ai/";
    downloadPage = "https://lmstudio.ai/download";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}

