# CuriOS sources packages
# Copy essential CuriOS configuration files from sources into a NixOS package.
# See:
# https://nixos.org/manual/nixos/stable/index.html#sec-building-image
# https://nixos.org/manual/nixpkgs/stable/#chap-stdenv
# https://nix.dev/tutorials/working-with-local-files#

{ lib, stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "curios-sources";
  version = "25.11.0";

  src = lib.fileset.toSource {
    root = ../../.;
    fileset = lib.fileset.unions [
      ../../configuration.nix
      ../../settings.nix
      ../../modules
      ../../pkgs
      ../../curios-install
      ../../logo.txt
    ];
  };
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -D -m 555 -t $out/bin/ curios-install
    install -D -m 644 -t $out/share/curios/ *.nix
    install -D -m 644 -t $out/share/curios/ logo.txt

    install -D -m 644 -t $out/share/curios/modules/ modules/*.nix
    install -D -m 644 -t $out/share/curios/modules/desktop-apps/ modules/desktop-apps/*.nix
    install -D -m 644 -t $out/share/curios/modules/desktop-apps/ modules/desktop-apps/*.png
    install -D -m 644 -t $out/share/curios/modules/desktop-apps/ modules/desktop-apps/*.svg
    install -D -m 644 -t $out/share/curios/modules/filesystems/ modules/filesystems/*.nix
    install -D -m 644 -t $out/share/curios/modules/hardened/ modules/hardened/*.nix
    install -D -m 644 -t $out/share/curios/modules/hardware/ modules/hardware/*.nix
    install -D -m 644 -t $out/share/curios/modules/platforms/ modules/platforms/*.nix

    install -D -m 644 -t $out/share/curios/pkgs/curios-dotfiles/ pkgs/curios-dotfiles/default.nix
    install -D -m 644 -t $out/share/curios/pkgs/curios-manager/ pkgs/curios-manager/default.nix

    runHook postInstall
  '';

  meta = {
    description = "Configuration nix files for CuriOS";
    homepage = "https://github.com/CuriosLabs/CuriOS";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
