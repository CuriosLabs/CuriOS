{ lib, stdenv, fetchFromGitHub, buildGoModule, go_1_26, installShellFiles
, makeBinaryWrapper }:

buildGoModule.override { go = go_1_26; } (finalAttrs: {
  pname = "basecamp";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "basecamp";
    repo = "basecamp-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7UiRrDptj7yuEFwToOfdunUMz/i3jRLR7CmMoYQjq6k=";
  };

  vendorHash = "sha256-DKClI1OivIa/x+X2602OAh0lO4jsLSiqsgsEQ2yCtNs=";

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
