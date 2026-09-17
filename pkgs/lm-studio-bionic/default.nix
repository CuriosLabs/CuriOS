# Install LM Studio Bionic from the AppImage published on the official website.
# See: https://lmstudio.ai/download
# See: https://wiki.nixos.org/wiki/Appimage

{ lib, fetchurl, makeDesktopItem, appimageTools }:
let
  pname = "lm-studio-bionic";
  version = "1.1.3-5";

  # Calculate the hash with:
  # nix --extra-experimental-features nix-command hash convert --hash-algo sha256 "$(nix-prefetch-url https://bionic-installers.lmstudio.ai/linux/x64/1.1.1-5/Bionic-1.1.1-5-x64.AppImage)"
  src = fetchurl {
    url =
      "https://bionic-installers.lmstudio.ai/linux/x64/${version}/Bionic-${version}-x64.AppImage";
    hash = "sha256-0rmi8lB2caV4LP64BmxusQpNsmdIH6MMhXX3oo88iZg=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };

  desktopItem = makeDesktopItem {
    name = "ai.lmstudio.bionic";
    exec = "/run/current-system/sw/bin/lm-studio-bionic";
    desktopName = "LM Studio Bionic";
    icon = "bionic";
    categories = [ "Development" "Science" "ArtificialIntelligence" ];
    terminal = false;
    type = "Application";
    startupWMClass = "ai.lmstudio.bionic";
  };
in appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "LM Studio Bionic";
    homepage = "https://lmstudio.ai/";
    downloadPage = "https://lmstudio.ai/download";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}