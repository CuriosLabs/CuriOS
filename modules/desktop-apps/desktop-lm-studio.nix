# Install lm-studio from the AppImage published on the official website.
# See: https://lmstudio.ai/download
# See: https://wiki.nixos.org/wiki/Appimage

{ pkgs, lib }:
let
  pname = "lmstudio";
  version = "0.3.36-1";

  src = pkgs.fetchurl {
    url =
      "https://installers.lmstudio.ai/linux/x64/${version}/LM-Studio-${version}-x64.AppImage";
    hash = "sha256-HwmwvMk2wH6bf/xgD07fWxF3JuGTYZmy7mK93F4LA+4=";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };

  desktopItem = pkgs.makeDesktopItem {
    name = "ai.lmstudio";
    exec = "/run/current-system/sw/bin/lm-studio";
    desktopName = "LM Studio local AI";
    icon = "lmstudio";
    categories = [ "Science" "ArtificialIntelligence" ];
    terminal = true;
  };
in pkgs.appimageTools.wrapType2 {
  inherit pname version pkgs src;

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    mkdir -p $out/share/icons/hicolor/1024x1024/apps
    install -m 444 -D ${appimageContents}/lm-studio.png $out/share/icons/hicolor/1024x1024/apps/lmstudio.png
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

