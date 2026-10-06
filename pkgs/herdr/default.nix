{ lib, pkgs, stdenv, rustPlatform, fetchFromGitHub, zig_0_16, installShellFiles
, cctools, xcbuild, versionCheckHook, nix-update-script, }:
let
  desktopItem = pkgs.makeDesktopItem {
    name = "dev.herdr.herdrdev";
    exec = "xdg-terminal-exec herdr";
    desktopName = "Herdr";
    icon = "herdr";
    categories = [ "Development" ];
    terminal = false;
    type = "Application";
  };
in rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr";
  version = "0.9.3";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-uu452Xe23pSvFk7w7fKPjiaqY5QenUIljao2SFAxpc0=";
  };

  cargoHash = "sha256-+gTWtEheyuI59yf2PqRbcbcFIW+/cYb7zZ2mPv2VN0Y=";

  zigDeps = zig_0_16.fetchDeps {
    inherit (finalAttrs) pname version;
    src = "${finalAttrs.src}/vendor/libghostty-vt";
    fetchAll = true;
    hash = "sha256-Cy0DdSvce+fhOFIfxHMQGF2b2j16UkS27UpGbfC42XI=";
  };

  nativeBuildInputs = [ zig_0_16 installShellFiles ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ cctools xcbuild ];

  # Upstream binary tests are renamed, added, or changed between releases and
  # depend on host process details, so Nix-only patches for them are brittle.
  doCheck = false;

  dontUseZigBuild = true;
  dontUseZigCheck = true;
  dontUseZigInstall = true;

  postConfigure = ''
    export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
    cp -rL ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  postInstall = ''
    mkdir -p $out/share
    cp -r ${desktopItem}/share/applications $out/share
    install -Dm644 assets/logo.svg $out/share/icons/hicolor/scalable/apps/herdr.svg
  '' + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd herdr \
      --bash <("$out/bin/herdr" completion bash) \
      --fish <("$out/bin/herdr" completion fish) \
      --zsh <("$out/bin/herdr" completion zsh)
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript =
    nix-update-script { extraArgs = [ "--custom-dep" "zigDeps" ]; };

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://herdr.dev";
    changelog =
      "https://github.com/herdrdev/herdr/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ agilesteel faukah kevinpita ];
    mainProgram = "herdr";
    platforms = lib.platforms.unix;
  };
})
