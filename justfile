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
  echo "Keep going..."
  # Change some version number in nix file to match $releaseNumber
  sed "s/nixos\.variant_id = \".*/nixos.variant_id = \"${releaseNumber}\";/g" -i ./configuration.nix
  sed "s/version = \".*/version = \"${releaseNumber}\";/g" -i ./pkgs/curios-sources/default.nix
  if [[ "{{branch}}" == release* ]]; then
    if [[ $(git status --porcelain --untracked-files=no | wc -l) -gt 0 ]]; then
      git commit -a -m "Release ${releaseNumber}"
    fi
  fi
  printf "Launch nix-build...\n"
  nix-build '<nixpkgs/nixos>' --show-trace --cores 0 --max-jobs auto -A config.system.build.isoImage -I nixos-config=./iso/iso-minimal.nix
  # Save and rename ISO file
  cp ./result/iso/nixos-minimal-*.iso "${isoFilePath}"
  sha256sum "${isoFilePath}" >>"${isoFilePath}".sha256
  chmod 0444 "${isoFilePath}".sha256
  printf "\e[32m Build done...\e[0m\n"

# Cleaning build and test artifacts.
clean:
  rm -rf ./result
  nix-store --gc

# Linting Bash scripts and Nix files.
lint:
  @echo 'Linting Nix files...'
  for file in `fd --type f ".nix" .`; do statix check $file; done
  @echo 'Linting Bash files...'
  shellcheck --color=always -f tty -x ./curios-install

# Push build ISO file to github as a release.
publish:
  #!/usr/bin/env bash
  set -euxo pipefail
  gh auth status
  if [[ "{{branch}}" != release* ]]; then
    printf "\e[31m Wrong git branch - not a release!\e[0m\n"
    exit 1
  else
    printf "\e[32m Github release upload...\e[0m\n"
    releaseNumber=$(sed -E "s/release\/(.+)/\1/" <<<"{{branch}}")
    isoFilename="CuriOS_${releaseNumber}_{{platform}}.iso"
    isoFilePath="./iso/${isoFilename}"
    if [ ! -f "$isoFilePath" ]; then
      printf "\e[33m ISO file %s not found! Launch `just build` first.\e[0m\n" "${isoFilePath}"
      exit 1
    fi
    git push --set-upstream origin "{{branch}}"
    gh release create "$releaseNumber" --target "{{branch}}" --title "$releaseNumber" --prerelease --generate-notes
    gh release upload "$releaseNumber" "$isoFilePath"
    gh release upload "$releaseNumber" "$isoFilePath".sha256
  fi

# Run all integrations tests sequentially
test-all:
  for file in `fd --type f ".nix" ./tests/`; do statix check $file; done
  for file in `fd --type f ".nix" ./tests/`; do nix-build $file --show-trace; done

# Run a single integration test, the target name must match the nix filename in ./tests/ (i.e basics).
test-unit target:
  statix check "./tests/{{target}}.nix"
  nix-build "./tests/{{target}}.nix" --show-trace

