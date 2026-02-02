# Just recipes
# variables
name := 'CuriOS'
owner := 'CuriosLabs'
branch := '$(git branch --show-current)'
platform := 'amd64_intel'

# Default option list available recipes.
default:
  @just --list

# Build an iso image of the current git branch.
build:
  #!/usr/bin/env bash
  set -euxo pipefail
  releaseNumber=""
  if [[ "{{branch}}" == testing || "{{branch}}" == feature* ]]; then
    releaseNumber=$(date --utc "+%Y%m%d.%H%M")
    releaseNumber="unstable-${releaseNumber}"
  else
    if [[ "{{branch}}" != release* ]]; then
      printf "\e[31m Wrong git branch - not a release!\e[0m\n"
      exit 1
    fi
    releaseNumber=$(sed -E "s/release\/(.+)/\1/" <<<"{{branch}}")
  fi
  isoFilename="CuriOS_${releaseNumber}_{{platform}}.iso"
  isoFilePath="./iso/${isoFilename}"
  printf "\e[32m Building %s file...\e[0m\n" "${isoFilePath}"
  # Check if iso file already exist
  if [ -f "$isoFilePath" ]; then
    printf "\e[33m ISO file %s already exist.\e[0m\n" "${isoFilePath}"
    exit 1
  fi

# Cleaning build result folder.
clean:
  rm -rf ./result

# debug recipes
debug:
  echo "Git branch: {{branch}}"

# Linting Bash scripts and Nix files.
lint:
  @echo 'Linting Nix files...'
  for file in `fd --type f ".nix" .`; do statix check $file; done
  @echo 'Linting Bash files...'
  shellcheck --color=always -f tty -x ./curios-install ./iso/build.sh

