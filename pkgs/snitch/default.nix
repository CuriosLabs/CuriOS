# snitch package.
# snitch - a friendlier ss/netstat for humans.

{ lib, stdenv, fetchFromGitHub, buildGoModule, installShellFiles, makeBinaryWrapper }:
buildGoModule rec {
  pname = "snitch";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "karol-broda";
    repo = "snitch";
    tag = "v${version}";
    hash = "sha256-SssAiRUfUaDgAoVO2rDacru8e914Wl+4sA4JQ4Mv4eA=";
  };

  vendorHash = "sha256-fX3wOqeOgjH7AuWGxPQxJ+wbhp240CW8tiF4rVUUDzk=";

  nativeBuildInputs = [
    installShellFiles
    makeBinaryWrapper
  ];

  ldflags = [
   "-s"
   "-w"
   "-X snitch/cmd.Version=${version}"
  ];

  meta = {
    description = "a friendlier ss/netstat for humans";
    homepage = "https://github.com/karol-broda/snitch";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "snitch";
  };
}
