# CuriOS manager COSMIC applet

{ lib, stdenv, fetchFromGitHub, pkg-config, rustPlatform, just, libcosmicAppHook
, nix-update-script }:
rustPlatform.buildRustPackage rec {
  pname = "curios-manager-applet";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "CuriosLabs";
    repo = "curios-manager-applet";
    tag = "${version}";
    hash = "sha256-mLYM5PE9403MPaUnIMHfc9neLOrSPVEDFfcg8u0Ybw8=";
  };

  cargoHash = "sha256-yX2NHr7yahTQ1ZzIVKtw8yO9IreBOVZBoBiURWjHbvE=";

  nativeBuildInputs = [ pkg-config just libcosmicAppHook ];

  dontUseJustBuild = true;
  dontUseJustCheck = true;

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "bin-src"
    "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/${pname}"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "CuriOS manager COSMIC applet";
    homepage = "https://github.com/CuriosLabs/curios-manager-applet";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "curios-manager-applet";
  };
}
