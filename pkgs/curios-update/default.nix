# CuriOS updater packages.
# Check for a new release online and update /etc/nixos/

{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation rec {
  pname = "curios-update";
  version = "0.6";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./bin
    ];
  };

  dontPatch = false;
  dontConfigure = true;
  dontBuild = true;
  postPatch = ''
    patchShebangs
  '';
  installPhase = ''
    runHook preInstall

    mkdir -p  $out/bin/
    install -D -m 555 -t $out/bin/ bin/curios-update

    runHook postInstall
  '';

  meta = {
    description = "CuriOS updater";
    homepage = "https://github.com/VideoCurio/nixos-configuration";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}