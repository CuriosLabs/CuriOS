{ lib, stdenv, fetchFromGitHub, buildGoModule, go_1_26, installShellFiles
, makeBinaryWrapper }:

buildGoModule.override { go = go_1_26; } (finalAttrs: {
  pname = "basecamp";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "basecamp";
    repo = "basecamp-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mYI3Fa1tFZ8qCXYd8MRsAwc8pwb4BYtPkoQae6QemJE=";
  };

  vendorHash = "sha256-gZPkROD2Zu47TLDS2Qjea5VVe2xO85ekPfKvDEQRp4U=";

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
