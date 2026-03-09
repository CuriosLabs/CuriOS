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

# Launch the ISO curios-install bash script directly. Do NOT complete it! It will really erase your selected disk!
install:
  ./curios-install

# Linting Bash scripts and Nix files.
lint:
  @echo 'Linting Nix files...'
  for file in `fd --type f ".nix" .`; do statix check $file; done
  @echo 'Linting Bash files...'
  shellcheck --color=always -f tty -x ./curios-install

# List all curios options and their current default values for this project.
list-options:
  nixos-option -I nixos-config=./modules/default.nix -r curios

# WARNING! Upgrade a NixOS system current configuration to the current CuriOS git branch.
nixos-upgrade:
  #!/usr/bin/env bash
  set -euxo pipefail
  if ! command -v nixos-rebuild >/dev/null; then
    printf "\e[31m Not a Nixos system.\e[0m\n"
    exit 1
  fi
  DOTFILES_VERSION="0.0"
  CURRENT_KEYBOARD="us"
  if command -v curios-dotfiles >/dev/null; then
    DOTFILES_VERSION=$(curios-dotfiles --version)
  fi
  printf "\e[31m CAUTION! This will modify your system.\e[0m\n"
  read -p "Proceed with installation? (Y)es / (N)o / (C)ancel: " yn
  case $yn in
    [Yy]*)
      printf "\e[32m Launching Nix garbage collector...\e[0m\n"
      sudo nix-store --gc
      printf "\e[32m Installing Curios...\e[0m\n"
      sudo install -D -m 644 -t /etc/nixos/ ./configuration.nix
      if [ ! -f /etc/nixos/settings.nix ]; then
        sudo install -D -m 644 -t /etc/nixos/ ./settings.nix
        printf "Default settings.nix file installed! Edit /etc/nixos/settings.nix to match your username."
      fi
      sudo install -D -m 644 -t /etc/nixos/ ./logo.txt
      sudo mkdir -p /etc/nixos/modules/
      sudo cp -r -f ./modules/ /etc/nixos/
      sudo mkdir -p /etc/nixos/pkgs/
      sudo cp -r -f ./pkgs/ /etc/nixos/
      NIX_CHANNEL_URL=$(grep -oP -m 1 'channel\s*=\s*"\K[^"]+' /etc/nixos/configuration.nix)
      if sudo nix-channel --list | grep -q "$NIX_CHANNEL_URL"; then
        printf "\e[32m Nix channel is already up-to-date.\e[0m\n"
      else
        printf "Updating Nix channel..."
        sudo nix-channel --add "$NIX_CHANNEL_URL" nixos
        sudo nix-channel --update
      fi
      if command -v curios-update >/dev/null; then
        if curios-update --help 2>&1 | grep -q -- "--export"; then
          sudo curios-update --export
        else
          printf "\e[31m curios-update --export is NOT supported!\e[0m\n"
        fi
      fi

      source /etc/os-release
      if [ "$VARIANT_ID" == "25.11.4" ]; then
        sudo sed -i 's/desktop\.apps/desktop/g' /etc/nixos/settings.nix
        sudo sed -i 's/desktop\.cosmic/cosmic/g' /etc/nixos/settings.nix
        #sudo curios-update --export
        #sudo sed -i '15,259d' /etc/nixos/settings.nix
      fi

      sudo nixos-rebuild switch --upgrade --cores 0 --max-jobs auto
      CURRENT_KEYBOARD=$(nixos-option curios.system.keyboard | sed -n '/^Value:/{n;p;}' | tr -d '" ')
      if [[ $(curios-dotfiles --version) != "$DOTFILES_VERSION" ]]; then
        HOME_DIR="/home/*/"
        printf "\e[32m Updating CuriOS dotfiles...\e[0m\n"
        for DIR in $HOME_DIR; do
          if [[ -d "$DIR" && "$DIR" != */lost+found/ ]]; then
            OWNER=$(stat -c '%U' "$DIR")
            sudo -u "$OWNER" curios-dotfiles --lang "$CURRENT_KEYBOARD" "$DIR"
          fi
        done
      fi
      printf "\e[32m Done.\e[0m\n"
      ;;
    [Nn]*) echo "No selected"; exit;;
    [Cc]*) echo "Cancel selected"; exit;;
    *) echo "Invalid input"; exit 1;;
  esac

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

