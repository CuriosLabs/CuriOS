# CuriOS dotfiles packages.
# Set COSMIC, ZSH and various configuration files.

{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-dotfiles";
  version = "0.20";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-dotfiles";
    rev = version;
    hash = "sha256-DZ7cNopD5qCuHJDO6k1VXCeCVV9WYogGSozNgtP33fU=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin/
    mkdir -p $out/share/
    mkdir -p $out/share/backgrounds/curios/
    mkdir -p $out/share/themes/curios/

    install -D -m 555 -t $out/bin/ curios-dotfiles
    cp -r .config/ $out/share/
    install -D -m 644 -t $out/share/ .npmrc
    install -D -m 644 -t $out/share/ .zshrc
    install -D -m 444 -t $out/share/backgrounds/curios/ wallpapers/*.jpg
    install -D -m 444 -t $out/share/themes/curios/ themes/*.ron

    runHook postInstall
  '';

  meta = {
    description = "COSMIC Desktop Environment configuration files for CuriOS";
    homepage = "https://github.com/CuriosLabs/curios-dotfiles";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
