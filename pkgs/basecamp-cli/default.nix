{ lib, stdenv, fetchFromGitHub, buildGoModule, go_1_26, installShellFiles
, makeBinaryWrapper }:

buildGoModule.override { go = go_1_26; } (finalAttrs: {
  pname = "basecamp";
  version = "0.29.0";

  src = fetchFromGitHub {
    owner = "basecamp";
    repo = "basecamp-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-XI86HEicpxyaKPrjQe9U7kMskXhLheDSD6hiqx7TFbo=";
  };

  vendorHash = "sha256-7OOmoZp90XyeXz6As8zVsaaslPWIeNDplenzbOEuE3A=";

  subPackages = [ "cmd/basecamp" ];

  ldflags = [ "-s" "-w" "-X internal/version.Version=${finalAttrs.version}" ];

  nativeBuildInputs = [ installShellFiles makeBinaryWrapper ];

  postInstall =
    lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd basecamp \
        --bash <($out/bin/basecamp completion bash) \
        --fish <($out/bin/basecamp completion fish) \
        --zsh  <($out/bin/basecamp completion zsh)
    '';

  meta = {
    description = "Command-line interface for Basecamp";
    homepage = "https://github.com/basecamp/basecamp-cli";
    changelog =
      "https://github.com/basecamp/basecamp-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "basecamp";
  };
})
