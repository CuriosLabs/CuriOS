# CuriOS Manager package.
# Various tools to manage your CuriOS system.

{ lib, stdenvNoCC, fetchFromGitHub, pkgs }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-manager";
  version = "0.9";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-manager";
    rev = version;
    hash = "sha256-EEqMw02TDtm8kH/UwgaDgMCXif+iqXJ8JUUN3oyCKYI=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  #postPatch = ''
  #  patchShebangs
  #'';
  desktopItem = pkgs.makeDesktopItem {
    name = "dev.curioslabs.curiosmanager";
    exec = "/run/current-system/sw/bin/alacritty -e curios-manager";
    desktopName = "CuriOS Manager CLI";
    icon = "desktop-curios-manager";
    categories = [ "System" ];
    terminal = true;
  };
  installPhase = ''
    runHook preInstall

    mkdir -p  $out/bin/
    install -D -m 555 -t $out/bin/ pkgs/curios-manager/bin/curios-manager
    install -D -m 555 -t $out/bin/ pkgs/curios-manager/bin/curios-update

    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp pkgs/curios-manager/share/icons/hicolor/scalable/apps/nixos.svg $out/share/icons/hicolor/scalable/apps/desktop-curios-manager.svg

    runHook postInstall
  '';

  meta = {
    description = "CuriOS manager";
    homepage = "https://github.com/CuriosLabs/curios-manager";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
