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
  nix-build '<nixpkgs/nixos>' --show-trace --cores 0 --max-jobs auto -A config.system.build.isoImage -I nixos-config=./iso/iso-installer.nix
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

# Report newer git tags or commits for pkgs/ using fetchFromGitHub. Pass a package directory name to check only that one.
check-pkg-updates pkg='':
  #!/usr/bin/env bash
  set -euo pipefail
  export GIT_TERMINAL_PROMPT=0
  export LC_ALL=C

  if ! command -v git >/dev/null; then
    printf "\e[31mgit is required.\e[0m\n"
    exit 1
  fi

  pkg="{{pkg}}"
  updates=0
  errors=0
  checked=0
  skipped=()
  errfile=$(mktemp)
  trap 'rm -f "$errfile"' EXIT

  trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
  }

  attr() {
    local name="$1"
    local block="$2"
    local value
    value=$(printf '%s\n' "$block" | grep -m1 -oP "^\s*${name}\s*=\s*\K[^;]+" || true)
    trim "$value"
  }

  unquote() {
    local s="$1"
    if [[ "$s" == \"*\" && "$s" == *\" ]]; then
      s="${s:1:${#s}-2}"
    fi
    printf '%s' "$s"
  }

  resolve_pin() {
    local expr version="$2"
    expr=$(trim "$1")
    if [[ "$expr" == \"*\" && "$expr" == *\" ]]; then
      expr=$(unquote "$expr")
      local token='${finalAttrs.version}'
      expr="${expr//"$token"/$version}"
      token='${version}'
      expr="${expr//"$token"/$version}"
      if [[ "$expr" == *'${'* ]]; then
        return 1
      fi
      expr="${expr#refs/tags/}"
      printf '%s' "$expr"
      return 0
    fi
    case "$expr" in
      version|finalAttrs.version)
        if [[ -z "$version" ]]; then
          return 1
        fi
        printf '%s' "$version"
        ;;
      *)
        return 1
        ;;
    esac
  }

  is_commit() {
    local pin="$1"
    if [[ "$pin" =~ ^[0-9a-fA-F]{40}$ ]]; then
      return 0
    fi
    if [[ "$pin" =~ [a-fA-F] && "$pin" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
      return 0
    fi
    return 1
  }

  is_prerelease() {
    local re='[._-](alpha|beta|rc|pre|preview|dev|nightly|snapshot)([._-]|[0-9]|$)'
    [[ "$1" =~ $re ]]
  }

  is_semver() {
    local re='^[vV]?[0-9]+(\.[0-9]+)+'
    [[ "$1" =~ $re ]]
  }

  ver_gt() {
    if [[ "$1" == "$2" ]]; then
      return 1
    fi
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" == "$1" ]]
  }

  normalize_ver() {
    local v="$1"
    v="${v#v}"
    v="${v#V}"
    printf '%s' "$v"
  }

  fetch_block() {
    awk '
      function count(s, c,    n, i) {
        n = 0
        for (i = 1; i <= length(s); i++)
          if (substr(s, i, 1) == c) n++
        return n
      }
      /fetchFromGitHub[[:space:]]*\{/ && !found { found = 1; depth = 0 }
      found {
        print
        depth += count($0, "{") - count($0, "}")
        if (depth <= 0) exit
      }
    ' "$1"
  }

  # Pick the highest stable tag. Pre-releases are ignored unless force_pre=1
  # or the pinned ref is itself a pre-release.
  latest_tag() {
    local pin="$1"
    local force_pre="$2"
    shift 2
    local include_pre=0 tag norm best="" best_norm="" pin_has_v=0
    if [[ "$force_pre" == 1 ]] || is_prerelease "$pin"; then
      include_pre=1
    fi
    if [[ "$pin" == [vV]* ]]; then
      pin_has_v=1
    fi
    for tag in "$@"; do
      if ! is_semver "$tag"; then
        continue
      fi
      if (( include_pre == 0 )) && is_prerelease "$tag"; then
        continue
      fi
      norm=$(normalize_ver "$tag")
      if [[ -z "$best" ]] || ver_gt "$norm" "$best_norm"; then
        best="$tag"
        best_norm="$norm"
      elif [[ "$norm" == "$best_norm" ]]; then
        if (( pin_has_v == 1 )) && [[ "$tag" == [vV]* && "$best" != [vV]* ]]; then
          best="$tag"
        elif (( pin_has_v == 0 )) && [[ "$tag" != [vV]* && "$best" == [vV]* ]]; then
          best="$tag"
        fi
      fi
    done
    printf '%s' "$best"
  }

  shopt -s nullglob
  if [[ -n "$pkg" ]]; then
    files=("./pkgs/${pkg}/default.nix")
    if [[ ! -f "${files[0]}" ]]; then
      printf "\e[31mPackage '%s' not found in pkgs/.\e[0m\n" "$pkg"
      exit 1
    fi
  else
    files=(./pkgs/*/default.nix)
  fi

  if [[ -n "$pkg" ]] && ! grep -q 'fetchFromGitHub' "${files[0]}"; then
    printf "\e[33m%s does not use fetchFromGitHub.\e[0m\n" "$pkg"
    exit 0
  fi

  printf "Checking fetchFromGitHub packages in pkgs/...\n"
  printf "  %-22s %-36s %-12s %s\n" "PACKAGE" "REPOSITORY" "PIN" "STATUS"

  for file in "${files[@]}"; do
    name=$(basename "$(dirname "$file")")
    if ! grep -q 'fetchFromGitHub' "$file"; then
      skipped+=("$name")
      continue
    fi

    version=$(grep -m1 -oP '^\s*version\s*=\s*"\K[^"]+' "$file" || true)
    block=$(fetch_block "$file")
    owner=$(unquote "$(attr owner "$block")")
    repo=$(unquote "$(attr repo "$block")")
    raw_ref=$(attr tag "$block")
    if [[ -z "$raw_ref" ]]; then
      raw_ref=$(attr rev "$block")
    fi

    if [[ -z "$owner" || -z "$repo" || -z "$raw_ref" ]]; then
      printf "  %-22s %-36s \e[31mcould not parse fetchFromGitHub\e[0m\n" "$name" "${owner}/${repo}"
      errors=$((errors + 1))
      continue
    fi

    if ! pin=$(resolve_pin "$raw_ref" "$version"); then
      printf "  %-22s %-36s \e[31munresolved ref %s\e[0m\n" "$name" "${owner}/${repo}" "$raw_ref"
      errors=$((errors + 1))
      continue
    fi

    url="https://github.com/${owner}/${repo}.git"
    if ! remote=$(git ls-remote --tags --refs "$url" 2>"$errfile"); then
      msg="failed to list tags"
      IFS= read -r errline <"$errfile" || true
      if [[ -n "${errline:-}" ]]; then
        msg="$errline"
      fi
      printf "  %-22s %-36s %-12s \e[31m%s\e[0m\n" "$name" "${owner}/${repo}" "$pin" "$msg"
      errors=$((errors + 1))
      continue
    fi

    tags=()
    shas=()
    if [[ -n "$remote" ]]; then
      while read -r sha tag; do
        if [[ -z "${tag:-}" ]]; then
          continue
        fi
        tags+=("$tag")
        shas+=("$sha")
      done < <(printf '%s\n' "$remote" | awk 'NF >= 2 { sub("refs/tags/", "", $2); print $1, $2 }')
    fi

    # A commit pin that matches a tag is compared as that tag. Otherwise it is
    # compared to the default branch tip: ls-remote cannot prove ancestry.
    if is_commit "$pin"; then
      matched=""
      for i in "${!shas[@]}"; do
        sha="${shas[$i]}"
        tag="${tags[$i]}"
        if [[ "$sha" != "$pin" && "$sha" != "$pin"* ]]; then
          continue
        fi
        if ! is_semver "$tag"; then
          continue
        fi
        if [[ -z "$matched" ]] || ver_gt "$(normalize_ver "$tag")" "$(normalize_ver "$matched")"; then
          matched="$tag"
        fi
      done
      if [[ -z "$matched" ]]; then
        if ! head_sha=$(git ls-remote "$url" HEAD 2>"$errfile" | awk '{print $1}'); then
          printf "  %-22s %-36s %-12s \e[31mfailed to query HEAD\e[0m\n" "$name" "${owner}/${repo}" "$pin"
          errors=$((errors + 1))
          continue
        fi
        checked=$((checked + 1))
        if [[ -n "$head_sha" && ( "$head_sha" == "$pin" || "$head_sha" == "$pin"* ) ]]; then
          printf "  %-22s %-36s %-12s \e[32mup to date\e[0m\n" "$name" "${owner}/${repo}" "$pin"
        else
          printf "  %-22s %-36s %-12s \e[33mtip %s\e[0m\n" "$name" "${owner}/${repo}" "$pin" "${head_sha:0:12}"
          updates=$((updates + 1))
        fi
        continue
      fi
      pin="$matched"
    fi

    checked=$((checked + 1))
    if (( ${#tags[@]} > 0 )); then
      latest=$(latest_tag "$pin" 0 "${tags[@]}")
    else
      latest=""
    fi
    pre_note=""
    if [[ -z "$latest" && ${#tags[@]} -gt 0 ]]; then
      latest=$(latest_tag "$pin" 1 "${tags[@]}")
      if is_prerelease "$latest"; then
        pre_note=" (pre-release)"
      fi
    fi

    if [[ -z "$latest" ]]; then
      printf "  %-22s %-36s %-12s \e[33mno version tags\e[0m\n" "$name" "${owner}/${repo}" "$pin"
      errors=$((errors + 1))
      continue
    fi

    pin_norm=$(normalize_ver "$pin")
    latest_norm=$(normalize_ver "$latest")
    if ver_gt "$latest_norm" "$pin_norm"; then
      printf "  %-22s %-36s %-12s \e[33m-> %s%s\e[0m\n" "$name" "${owner}/${repo}" "$pin" "$latest" "$pre_note"
      updates=$((updates + 1))
    elif ver_gt "$pin_norm" "$latest_norm"; then
      printf "  %-22s %-36s %-12s \e[32mahead of %s\e[0m\n" "$name" "${owner}/${repo}" "$pin" "$latest"
    else
      printf "  %-22s %-36s %-12s \e[32mup to date\e[0m\n" "$name" "${owner}/${repo}" "$pin"
    finixos-option nixpkgs.config 2>&1
  done

  printf "\n"
  if (( updates > 0 )); then
    printf "\e[33m%d update(s) found.\e[0m\n" "$updates"
  else
    printf "\e[32mNo updates found.\e[0m\n"
  fi
  if (( errors > 0 )); then
    printf "\e[31m%d error(s).\e[0m\n" "$errors"
  fi
  if (( ${#skipped[@]} > 0 )); then
    printf "Skipped (not fetchFromGitHub): %s\n" "${skipped[*]}"
  fi
  if (( errors > 0 )); then
    exit 1
  fi

