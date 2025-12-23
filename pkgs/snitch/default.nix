# snitch package.
# snitch - a friendlier ss/netstat for humans.

{ lib, stdenv, fetchFromGitHub, buildGoModule, installShellFiles, makeBinaryWrapper }:
buildGoModule rec {
  pname = "snitch";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "karol-broda";
    repo = "snitch";
    tag = "v${version}";
    hash = "sha256-ZXVQN09vCwf2ZBaUJ8ugCvknYVutIJn0LvlHd/t01Dg=";
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
