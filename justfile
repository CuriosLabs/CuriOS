# Just recipes
# variables
name := 'CuriOS'
owner := 'CuriosLabs'
branch := '$(git branch --show-current)'
platform := 'amd64_intel'
r2_bucket := 'curios-iso'
r2_public_url := 'https://iso.curioslabs.dev'

# Default option list available recipes.
default:
  @just --list

# Build an iso image of the current git branch.
build: lint update-nixos-hardware
  #!/usr/bin/env bash
  set -euxo pipefail
  releaseNumber=""
  if [[ "{{branch}}" == testing || "{{branch}}" == unstable || "{{branch}}" == feature* ]]; then
    releaseNumber=$(date --utc "+%Y%m%d.%H%M")
    releaseNumber="unstable-${releaseNumber}"
  else
    if [[ "{{branch}}" != release* ]]; then
      printf "\e[31m Wrong git branch - not a release!\e[0m\n"
      exit 1
    fi
    releaseNumber=$(sed -E "s/release\/(.+)/\1/" <<<"{{branch}}")
  fi
  mkdir -p iso/
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
  # On the unstable branch, add/update the "nixos-unstable" channel and force
  # building against it regardless of the host's <nixpkgs> channel.
  NIXPKGS_ARG=""
  if [[ "{{branch}}" == unstable ]]; then
    sudo nix-channel --add https://channels.nixos.org/nixos-unstable nixos-unstable
    sudo nix-channel --update
    NIXPKGS_ARG="-I nixpkgs=channel:nixos-unstable"
  fi
  nix-build '<nixpkgs/nixos>' --show-trace --cores 0 --max-jobs auto -A config.system.build.isoImage -I nixos-config=./iso/iso-installer.nix $NIXPKGS_ARG
  # Save and rename ISO file
  cp ./result/iso/nixos-minimal-*.iso "${isoFilePath}"
  cd ./iso/
  sha256sum "${isoFilename}" >>"${isoFilename}".sha256
  chmod 0444 "${isoFilename}".sha256
  printf "\e[32m Build done...\e[0m\n"

# Cleaning build and test artifacts.
clean:
  rm -rf ./result
  rm -rf ./sbom
  if [ -f http_cache.sqlite ]; then rm http_cache.sqlite; else printf '\e[33m http_cache.sqlite not found!\e[0m\n'; fi
  nix-store --gc

# Launch the ISO curios-install bash script directly. Do NOT complete it! It will really erase your selected disk!
install:
  nix-build -E 'with import <nixpkgs> {}; callPackage ./pkgs/curios-sources/default.nix {}' && nix profile add ./result
  ./curios-install --verbose

# Generate a CycloneDX SBOM for a package name found in the nix store (i.e: opencode-desktop). Saved in ./sbom/.
sbom pkg:
  #!/usr/bin/env bash
  set -euo pipefail
  mkdir -p sbom/
  if [ -L "/run/current-system/sw/bin/{{pkg}}" ]; then
    store_path=$(readlink -f "/run/current-system/sw/bin/{{pkg}}")
  else
    store_path=$(ls -d /nix/store/*-{{pkg}}-*/ 2>/dev/null | grep -Ev '\.(drv|lock|env)/$' | sort -V | tail -1)
  fi
  if [ -z "$store_path" ] || [ ! -e "$store_path" ]; then
    printf "\e[31m Package '{{pkg}}' not found in the nix store (neither /run/current-system/sw/bin nor /nix/store).\e[0m\n"
    exit 1
  fi
  name=$(basename "$store_path")
  printf "Generating SBOM for %s...\n" "$store_path"
  sbomnix \
    --cdx "./sbom/${name}.cdx.json" \
    --spdx "./sbom/${name}.spdx.json" \
    --csv "./sbom/${name}.csv" \
    "$store_path"
  printf "\e[32m SBOM written to ./sbom/${name}.cdx.json\e[0m\n"

# Generate an SLSA v1.0 provenance file for a package name found in the nix store (i.e: opencode-desktop). Saved in ./sbom/.
sbom-provenance pkg:
  #!/usr/bin/env bash
  set -euo pipefail
  mkdir -p sbom/
  if [ -L "/run/current-system/sw/bin/{{pkg}}" ]; then
    store_path=$(dirname "$(dirname "$(readlink -f "/run/current-system/sw/bin/{{pkg}}")")")
  else
    store_path=$(ls -d /nix/store/*-{{pkg}}-*/ 2>/dev/null | grep -Ev '\.(drv|lock|env)/$' | sort -V | tail -1)
  fi
  if [ -z "$store_path" ] || [ ! -e "$store_path" ]; then
    printf "\e[31m Package '{{pkg}}' not found in the nix store (neither /run/current-system/sw/bin nor /nix/store).\e[0m\n"
    exit 1
  fi
  name=$(basename "$store_path")
  printf "Generating provenance for %s...\n" "$store_path"
  provenance --out "./sbom/${name}-provenance.json" "$store_path"
  printf "\e[32m Provenance written to ./sbom/${name}-provenance.json\e[0m\n"

# Generate a CycloneDX SBOM for the whole current NixOS system (/run/current-system). Saved in ./sbom/.
sbom-system:
  #!/usr/bin/env bash
  set -euo pipefail
  mkdir -p sbom/
  system=$(readlink -f /run/current-system)
  printf "Generating SBOM for %s...\n" "$system"
  sbomnix \
    --cdx "./sbom/current-system.cdx.json" \
    --spdx "./sbom/current-system.spdx.json" \
    --csv "./sbom/current-system.csv" \
    "$system"
  printf "\e[32m SBOM written to ./sbom/current-system.cdx.json\e[0m\n"

# Generate an inverse dependency graph (PNG + CSV) matching <pattern> in the current NixOS system. Saved in ./sbom/.
sbom-graph pattern='heif' depth='6':
  #!/usr/bin/env bash
  set -euo pipefail
  mkdir -p sbom/
  system=$(readlink -f /run/current-system)
  printf "Generating inverse dependency graph for '%s'...\n" "{{pattern}}"
  nixgraph --inverse "{{pattern}}" --depth {{depth}} \
    --out "./sbom/{{pattern}}-graph.png" "$system"
  nixgraph --inverse "{{pattern}}" --depth {{depth}} \
    --out "./sbom/{{pattern}}-graph.csv" "$system"
  printf "\e[32m Graphs written to ./sbom/{{pattern}}-graph.png and ./sbom/{{pattern}}-graph.csv\e[0m\n"

# Linting Bash scripts and Nix files.
lint:
  @echo 'Linting Nix files...'
  for file in `fd --type f ".nix" .`; do statix check $file; done
  @echo 'Linting Bash files...'
  shellcheck --color=always -f tty -x ./curios-install && echo "shellcheck: SUCCESS"

# List all curios options and their current default values for this project.
list-options:
  nixos-option -I nixos-config=./modules/default.nix -r curios

# WARNING! Upgrade a NixOS system current configuration to the current CuriOS git branch.
nixos-upgrade: lint
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
      releaseNumber=""
      if [[ "{{branch}}" == testing || "{{branch}}" == unstable || "{{branch}}" == feature* ]]; then
        releaseNumber=$(date --utc "+%Y%m%d.%H%M")
        releaseNumber="unstable-${releaseNumber}"
      else
        if [[ "{{branch}}" != release* ]]; then
          printf "\e[31m Wrong git branch - not a release!\e[0m\n"
          exit 1
        fi
      releaseNumber=$(sed -E "s/release\/(.+)/\1/" <<<"{{branch}}")
      fi
      # Change some version number in nix file to match $releaseNumber
      sed "s/nixos\.variant_id = \".*/nixos.variant_id = \"${releaseNumber}\";/g" -i ./configuration.nix
      sed "s/version = \".*/version = \"${releaseNumber}\";/g" -i ./pkgs/curios-sources/default.nix

      printf "\e[32m Launching Nix garbage collector...\e[0m\n"
      sudo nix-store --gc

      printf "\e[32m Installing Curios...\e[0m\n"
      sudo install -D -m 644 -t /etc/nixos/ ./configuration.nix
      if [ ! -f /etc/nixos/settings.nix ]; then
        sudo install -D -m 644 -t /etc/nixos/ ./settings.nix
        printf "Default settings.nix file installed! Edit /etc/nixos/settings.nix to match your username."
      fi
      sudo install -D -m 644 -t /etc/nixos/ ./logo.txt
      #sudo mkdir -p /etc/nixos/modules/
      #sudo cp -r -f --preserve=mode ./modules/ /etc/nixos/

      sudo install -D -m 644 -t /etc/nixos/modules/ ./modules/*.nix
      sudo install -D -m 644 -t /etc/nixos/modules/desktop-apps/ ./modules/desktop-apps/*.nix
      sudo install -D -m 644 -t /etc/nixos/modules/desktop-apps/ ./modules/desktop-apps/*.png
      sudo install -D -m 644 -t /etc/nixos/modules/desktop-apps/ ./modules/desktop-apps/*.svg
      sudo install -D -m 644 -t /etc/nixos/modules/filesystems/ ./modules/filesystems/*.nix
      sudo install -D -m 644 -t /etc/nixos/modules/hardened/ ./modules/hardened/*.nix
      sudo install -D -m 644 -t /etc/nixos/modules/hardware/ ./modules/hardware/*.nix
      sudo install -D -m 644 -t /etc/nixos/modules/platforms/ ./modules/platforms/*.nix
      for pkg in ./pkgs/*; do sudo install -D -m 644 -t "/etc/nixos/${pkg}/" "$pkg"/*; done

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

      sudo nixos-rebuild switch --upgrade --cores 0 --max-jobs auto --show-trace 2>&1 | tee /tmp/nixos-upgrade.log
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
      if command -v aa-status >/dev/null; then
        if systemctl is-active --quiet apparmor.service; then
          printf "\e[32m Clearing AppArmor cache...\e[0m\n"
          sudo fd -d 1 . /var/cache/apparmor/ -E logprof -x rm -rf {}
          sudo truncate -s 0 /var/log/audit/audit.log
          sudo systemctl restart apparmor
        fi
      fi
      printf "\e[32m Done.\e[0m\n"
      ;;
    [Nn]*) echo "No selected"; exit;;
    [Cc]*) echo "Cancel selected"; exit;;
    *) echo "Invalid input"; exit 1;;
  esac

# Push source to GitHub and upload the ISO to Cloudflare R2. Configure "endpoint_url" in ~/.aws/config and connect with `aws configure`
publish: lint
  #!/usr/bin/env bash
  set -euxo pipefail
  gh auth status
  aws s3 ls "s3://{{r2_bucket}}/" >/dev/null
  if [[ "{{branch}}" != release* ]]; then
    printf "\e[31m Wrong git branch - not a release!\e[0m\n"
    exit 1
  else
    releaseNumber=$(sed -E "s/release\/(.+)/\1/" <<<"{{branch}}")
    if git rev-parse "$releaseNumber" >/dev/null 2>&1; then echo "Warning: Tag ${releaseNumber} already exists."; exit 1; fi

    isoFilename="CuriOS_${releaseNumber}_{{platform}}.iso"
    isoFilePath="./iso/${isoFilename}"
    if [ ! -f "$isoFilePath" ]; then
      printf "\e[33m ISO file %s not found! Launch `just build` first.\e[0m\n" "${isoFilePath}"
      exit 1
    fi
    if [ ! -f "${isoFilePath}.sha256" ]; then
      printf "\e[33m Checksum file %s.sha256 not found!\e[0m\n" "${isoFilePath}"
      exit 1
    fi

    git push --set-upstream origin "{{branch}}"
    printf "\e[32m Uploading ISO to Cloudflare R2...\e[0m\n"
    aws s3 cp "$isoFilePath" "s3://{{r2_bucket}}/${isoFilename}"
    aws s3 cp "${isoFilePath}.sha256" "s3://{{r2_bucket}}/${isoFilename}.sha256"
    printf "\e[32m Creating GitHub release...\e[0m\n"
    gh release create "$releaseNumber" --target "{{branch}}" --title "$releaseNumber" --prerelease --generate-notes \
      --notes "$(printf '## Download\n\n- ISO: {{r2_public_url}}/%s\n- SHA256: {{r2_public_url}}/%s.sha256\n' "${isoFilename}" "${isoFilename}")"
  fi

# Run all integrations tests sequentially
test-all:
  for file in `fd --type f ".nix" ./tests/`; do statix check $file; done
  for file in `fd --type f ".nix" ./tests/`; do nix-build $file --show-trace --no-out-link; done

# Run a single integration test, the target name must match the nix filename in ./tests/ (i.e basics).
test-unit target:
  statix check "./tests/{{target}}.nix"
  nix-build "./tests/{{target}}.nix" --show-trace --no-out-link

# Run the aarch64-linux (RPI4) platform compatibility test. Evaluates all modules with all options enabled and reports x86_64-only packages.
test-aarch64:
  statix check "./tests/platform-aarch64.nix"
  nix-build "./tests/platform-aarch64.nix" --show-trace --no-out-link

# Update the pinned nixos-hardware commit in the Raspberry Pi modules.
update-nixos-hardware:
  #!/usr/bin/env bash
  set -euo pipefail
  echo "Fetching latest nixos-hardware commit..."
  LATEST_COMMIT=$(curl -s https://api.github.com/repos/NixOS/nixos-hardware/commits/master | grep -oP '"sha": "\K[0-9a-f]{40}' | head -1)
  if [ -z "$LATEST_COMMIT" ]; then
    echo "Failed to fetch latest commit."
    exit 1
  fi
  CURRENT_COMMIT=$(grep -oP 'archive/\K[0-9a-f]+' ./modules/platforms/rpi4.nix | head -1)
  if [ "$CURRENT_COMMIT" = "$LATEST_COMMIT" ]; then
    echo "nixos-hardware is already up to date ($CURRENT_COMMIT)."
    exit 0
  fi
  echo "Latest commit: $LATEST_COMMIT"
  echo "Fetching SHA256..."
  SHA256=$(nix-prefetch-url --unpack "https://github.com/NixOS/nixos-hardware/archive/${LATEST_COMMIT}.tar.gz")
  echo "SHA256: $SHA256"
  for file in ./modules/platforms/rpi4.nix ./modules/platforms/rpi5.nix; do
    sed -i "s|archive/[0-9a-f]*.tar.gz|archive/${LATEST_COMMIT}.tar.gz|g" "$file"
    sed -i "s|sha256 = \".*\";|sha256 = \"${SHA256}\";|g" "$file"
  done
  echo "Updated nixos-hardware to commit ${LATEST_COMMIT} in:"
  echo "  - ./modules/platforms/rpi4.nix"
  echo "  - ./modules/platforms/rpi5.nix"

