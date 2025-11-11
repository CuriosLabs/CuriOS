# CuriOS Manager package.
# Various tools to manage your CuriOS system.

{ lib, stdenvNoCC, pkgs }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-manager";
  version = "0.6";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./bin
      ./share
    ];
  };

  dontPatch = false;
  dontConfigure = true;
  dontBuild = true;
  postPatch = ''
    patchShebangs
  '';
  desktopItem = pkgs.makeDesktopItem {
    name = "com.videocurio.curios.manager";
    exec = "/run/current-system/sw/bin/alacritty -e curios-manager";
    desktopName = "CuriOS Manager CLI";
    icon = "desktop-curios-manager";
    categories = [ "System" ];
    terminal = true;
  };
  installPhase = ''
    runHook preInstall

    mkdir -p  $out/bin/
    install -D -m 555 -t $out/bin/ bin/curios-manager

    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp share/icons/hicolor/scalable/apps/nixos.svg $out/share/icons/hicolor/scalable/apps/desktop-curios-manager.svg

    runHook postInstall
  '';

  meta = {
    description = "CuriOS manager";
    homepage = "https://github.com/VideoCurio/nixos-configuration";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}