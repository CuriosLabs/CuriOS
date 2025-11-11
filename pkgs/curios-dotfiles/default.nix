# CuriOS dotfiles packages.
# Set COSMIC, ZSH and various configuration files.

{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-dotfiles";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-dotfiles";
    rev = version;
    hash = "sha256-QwRt/qz1DPz/0jsi5eJ93v6qiTqdZRyow1Ijomm66Cs=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall

    mkdir -p  $out/bin/
    mkdir -p  $out/share/
    install -D -m 555 -t $out/bin/ curios-dotfiles
    cp -r .config/ $out/share/
    install -D -m 644 -t $out/share/ .zshrc
    install -D -m 644 -t $out/share/ .zshrc-ai.plugin.zsh

    runHook postInstall
  '';

  meta = {
    description = "COSMIC Desktop Environment configuration files for CuriOS";
    homepage = "https://github.com/CuriosLabs/curios-dotfiles";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}