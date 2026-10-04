# CuriOS dotfiles packages.
# Set COSMIC, ZSH and various configuration files.

{ lib, pkgs, stdenvNoCC, fetchFromGitHub, makeWrapper }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-dotfiles";
  version = "0.41.0";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-dotfiles";
    rev = version;
    hash = "sha256-Uml9uREL7Y3l9F7veqjCiRO6aGPnniPC/uZAMEHuvg8=";
  };

  buildInputs = [ pkgs.git pkgs.gnused pkgs.jq ];
  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;
  postPatch = ''
    patchShebangs .
  '';
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin/

    install -D -m 555 -t $out/bin/ curios-dotfiles
    wrapProgram $out/bin/curios-dotfiles --prefix PATH : ${
      lib.makeBinPath buildInputs
    }
    wrapProgram $out/bin/curios-dotfiles --prefix PATH : ${
      lib.makeBinPath buildInputs
    }

    runHook postInstall
  '';

  meta = {
    description = "COSMIC Desktop Environment configuration files for CuriOS";
    homepage = "https://github.com/CuriosLabs/curios-dotfiles";
    license = lib.licenses.gpl3Only;
    mainProgram = "curios-dotfiles";
    platforms = lib.platforms.linux;
  };
}
