# CuriOS Manager package.
# Various tools to manage your CuriOS system.

{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-manager";
  version = "0.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./bin
    ];
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall

    mkdir -p  $out/bin/
    install -D -m 555 -t $out/bin/ bin/curios-manager

    runHook postInstall
  '';

  meta = {
    description = "CuriOS manager";
    homepage = "https://github.com/VideoCurio/nixos-configuration";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}