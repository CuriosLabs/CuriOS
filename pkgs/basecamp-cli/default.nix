{ lib, stdenv, fetchFromGitHub, buildGoModule, go_1_26, installShellFiles
, makeBinaryWrapper }:

buildGoModule.override { go = go_1_26; } (finalAttrs: {
  pname = "basecamp";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "basecamp";
    repo = "basecamp-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1+jHfilH+YPyF0uc/jF3EorAlZ/WmrmD+bmwTJm4YLA=";
  };

  vendorHash = "sha256-KJ3/Lr2Zdue5yidZKLvETLHmoqUYmupiUn594aImSyE=";

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
