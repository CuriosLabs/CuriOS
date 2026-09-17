# Install lm-studio from the AppImage published on the official website.
# See: https://lmstudio.ai/download
# See: https://wiki.nixos.org/wiki/Appimage

{ lib, stdenv, fetchurl, makeDesktopItem, appimageTools, imagemagick
, patchelf }:
let
  pname = "lm-studio";
  version = "0.4.24-1";

  # Calculate the hash with:
  # nix --extra-experimental-features nix-command hash convert --hash-algo sha256 "$(nix-prefetch-url https://installers.lmstudio.ai/linux/x64/0.4.14-4/LM-Studio-0.4.14-4-x64.AppImage)"
  src = fetchurl {
    url =
      "https://installers.lmstudio.ai/linux/x64/${version}/LM-Studio-${version}-x64.AppImage";
    hash = "sha256-F8uKxjdPkYL8En764gaAJl48TBfZbq3xR+tf5hEak1M=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };

  desktopItem = makeDesktopItem {
    name = "ai.lmstudio";
    exec = "/run/current-system/sw/bin/lm-studio";
    desktopName = "LM Studio local AI";
    icon = "lmstudio";
    categories = [ "Science" "ArtificialIntelligence" ];
    terminal = false;
    type = "Application";
  };
in appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ imagemagick patchelf ];

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy and resize icon in correct folders
    for size in 48 64 128 256; do
      mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
      magick ${appimageContents}/lm-studio.png -background none -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/lmstudio.png
    done

    # lms CLI
    mkdir -p $out/bin
    install -D -m 755 -t $out/bin/ ${appimageContents}/resources/app/.webpack/lms

    patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" $out/bin/lms
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
