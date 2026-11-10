{ lib, stdenv, fetchFromGitHub, buildGoModule, go_1_26, installShellFiles
, makeBinaryWrapper }:

buildGoModule.override { go = go_1_26; } (finalAttrs: {
  pname = "basecamp";
  version = "0.26.0";

  src = fetchFromGitHub {
    owner = "basecamp";
    repo = "basecamp-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QUkKO1qMLxyE3RLT14Sw84pwiE/J1mse3kmEOdE07bk=";
  };

  vendorHash = "sha256-HQ4TfynVR5D3mNaiL05G9j7JVWejhvIh+dz9g47fZHw=";

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
