# CuriOS Manager package.
# Various tools to manage your CuriOS system.

{ lib, stdenvNoCC, fetchFromGitHub, pkgs, makeWrapper }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-manager";
  version = "0.20";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-manager";
    rev = version;
    hash = "sha256-4YY7zDMzHGzYLMGCMDRZcOBo6hLGKl/bFTSxUJRrG0k=";
  };

  buildInputs = [
    pkgs.btop
    #pkgs.cosmic-applibrary
    #pkgs.cosmic-launcher
    #pkgs.cosmic-osd
    #pkgs.cosmic-settings
    #pkgs.cosmic-store
    pkgs.curl
    #pkgs.curios-dotfiles
    pkgs.duf
    pkgs.fastfetch
    pkgs.fd
    pkgs.fwupd
    pkgs.gnutar
    pkgs.gdu
    pkgs.gum
    pkgs.jq
    pkgs.libnotify
    pkgs.smartmontools
    #pkgs.systemd
    pkgs.terminaltexteffects
    pkgs.wget
  ];
  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;
  postPatch = ''
    patchShebangs .
  '';
  desktopItem = pkgs.makeDesktopItem {
    name = "dev.curioslabs.curiosmanager";
    exec = "/run/current-system/sw/bin/alacritty -e curios-manager";
    desktopName = "CuriOS Manager TUI";
    icon = "curios";
    categories = [ "System" ];
    terminal = false;
    type = "Application";
  };
  installPhase = ''
    runHook preInstall

    mkdir -p  $out/bin/
    mkdir -p  $out/bin/functions/
    install -D -m 555 -t $out/bin/ pkgs/curios-manager/bin/curios-manager
    install -D -m 555 -t $out/bin/ pkgs/curios-manager/bin/curios-update
    install -D -m 444 -t $out/bin/ pkgs/curios-manager/bin/constants.sh
    install -D -m 444 -t $out/bin/functions pkgs/curios-manager/bin/functions/*
    wrapProgram $out/bin/curios-manager --prefix PATH : ${
      lib.makeBinPath buildInputs
    }
    wrapProgram $out/bin/curios-update --prefix PATH : ${
      lib.makeBinPath buildInputs
    }

    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp pkgs/curios-manager/share/icons/hicolor/scalable/apps/curios.svg $out/share/icons/hicolor/scalable/apps/curios.svg

    runHook postInstall
  '';

  meta = {
    description = "CuriOS manager";
    homepage = "https://github.com/CuriosLabs/curios-manager";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
