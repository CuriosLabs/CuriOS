# Install Open CAD Studio from the AppImage published on GitHub releases.
# See: https://github.com/HakanSeven12/OpenCADStudio/releases
# See: https://wiki.nixos.org/wiki/Appimage

{ lib, fetchurl, makeDesktopItem, appimageTools, imagemagick }:
let
  pname = "opencadstudio";
  version = "v2026.37";

  # Calculate the hash with:
  # nix --extra-experimental-features nix-command hash convert --hash-algo sha256 "$(nix-prefetch-url https://github.com/HakanSeven12/OpenCADStudio/releases/download/v2026.37/OpenCADStudio-v2026.37-linux-x86_64.AppImage)"
  src = fetchurl {
    url =
      "https://github.com/HakanSeven12/OpenCADStudio/releases/download/${version}/OpenCADStudio-${version}-linux-x86_64.AppImage";
    hash = "sha256-/9CRbrfXMvgewJ5yU5//vzyGWOOO7vEhQ1QNwYFhlI4=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };

  desktopItem = makeDesktopItem {
    name = "io.github.HakanSeven12.OpenCadStudio";
    exec = "/run/current-system/sw/bin/opencadstudio";
    desktopName = "Open CAD Studio";
    icon = "opencadstudio";
    categories = [ "Graphics" "Engineering" ];
    mimeTypes = [ "image/vnd.dwg" "image/vnd.dxf" ];
    terminal = false;
    type = "Application";
    startupWMClass = "io.github.HakanSeven12.OpenCadStudio";
  };
in appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ imagemagick ];

  extraInstallCommands = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    # copy and resize icon in correct folders
    for size in 48 64 128 256; do
      mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
      magick ${appimageContents}/usr/share/icons/hicolor/256x256/apps/io.github.HakanSeven12.OpenCadStudio.png -background none -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/opencadstudio.png
    done
  '';

  meta = {
    description =
      "Open CAD Studio - 2D/3D CAD application for DWG and DXF drawings";
    homepage = "https://github.com/HakanSeven12/OpenCADStudio";
    downloadPage = "https://github.com/HakanSeven12/OpenCADStudio/releases";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
