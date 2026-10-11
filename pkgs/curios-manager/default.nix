# CuriOS Manager package.
# Various tools to manage your CuriOS system.

{ lib, stdenvNoCC, fetchFromGitHub, pkgs, makeWrapper }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-manager";
  version = "0.52.5";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-manager";
    rev = version;
    hash = "sha256-EKNAo+3sJ165VBUDmO8iHnn+77crhSEDESu4QJTET0g=";
  };

  buildInputs = [
    pkgs.btop
    pkgs.coreutils
    pkgs.cryptsetup
    pkgs.duf
    pkgs.efitools
    pkgs.fastfetch
    pkgs.fd
    pkgs.fwupd
    pkgs.git
    pkgs.gdu
    pkgs.gum
    pkgs.hostname
    pkgs.jq
    pkgs.libnotify
    pkgs.libsecret
    pkgs.ncdu
    pkgs.nix-search-cli
    pkgs.nixos-option
    #pkgs.nvtopPackages.full
    pkgs.openssh
    pkgs.pamtester
    pkgs.restic
    pkgs.rsync
    pkgs.sbctl
    pkgs.smartmontools
    pkgs.snitch
    pkgs.terminaltexteffects
    pkgs.util-linux
    pkgs.xdg-utils
    pkgs.yubikey-manager
  ];
  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;
  postPatch = ''
    patchShebangs .
  '';
  desktopItem = pkgs.makeDesktopItem {
    name = "dev.curioslabs.curiosmanager";
    exec = "xdg-terminal-exec curios-manager";
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
    mainProgram = "curios-manager";
    platforms = lib.platforms.linux;
  };
}
