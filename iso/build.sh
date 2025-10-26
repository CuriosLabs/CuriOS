#!/usr/bin/env bash

# Build the CuriOS ISO file

set -eu
script_path="$(dirname "$0")"

# Temporary allowing build of a broken package once.
#export NIXPKGS_ALLOW_BROKEN=1
branch="$(git branch --show-current)"
platform="amd64_intel"
currentRelease=""
releaseNumber=""
if [[ "$branch" == testing || "$branch" == feature* ]]; then
  currentRelease="CuriOS"
  releaseNumber=$(date --utc "+%Y%m%d.%H%M")
  releaseNumber="unstable-${releaseNumber}"
else
  if [[ "$branch" != release* ]]; then
    printf "\e[31m Wrong git branch - not a release!\e[0m\n"
    exit 1
  fi
  currentRelease="CuriOS"
  releaseNumber=$(sed -E "s/release\/(.+)/\1/" <<< "$branch")
fi

isoFilename="${currentRelease}_${releaseNumber}_${platform}.iso"
isoFilePath="${script_path}/${isoFilename}"

printf "\e[32m Building %s file...\e[0m\n" "$isoFilename"
# Check if iso file already exist
if [ -f "$isoFilePath" ]; then
  printf "\e[33m ISO file %s already exist.\e[0m\n" "$isoFilename"
  exit 1
fi

# Check lint
printf "Lint bash script files...\n"
shellcheck --color=always -f tty -x ./../curios-install
shellcheck --color=always -f tty -x ./../pkgs/curios-update/bin/curios-update
printf "Lint pkgs/ nix files...\n"
for file in ./../pkgs/*/*.nix; do
  if [ -f "$file" ]; then
    statix check "$file"
  fi
done
printf "Lint modules/ nix files...\n"
for file in ./../modules/*/*.nix; do
  if [ -f "$file" ]; then
    statix check "$file"
  fi
done
printf "Lint main nix files...\n"
for file in ./../*.nix; do
  if [ -f "$file" ]; then
    statix check "$file"
  fi
done

# Change some version number in nix file to match $releaseNumber
sed "s/nixos\.variant_id = \".*/nixos.variant_id = \"${releaseNumber}\";/g" -i ./../configuration.nix
sed "s/version = \".*/version = \"${releaseNumber}\";/g" -i ./../pkgs/curios-sources/default.nix
if [[ "$branch" == release* ]]; then
  git commit -a -m "Release ${releaseNumber}"
fi

# Build packages
#printf "Build custom pkgs...\n"
# nix-build && nix-env -i -f default.nix
#nix-build -E 'with import <nixpkgs> {}; callPackage ./pkgs/curios-sources {}'
#nix-shell -E 'with import <nixpkgs> {}; callPackage ./pkgs/curios-dotfiles {}'

printf "Launch nix-build...\n"
nix-build '<nixpkgs/nixos>' --show-trace --cores 0 --max-jobs auto -A config.system.build.isoImage -I nixos-config=./iso-minimal.nix

#### Save and rename ISO file
cp ./result/iso/nixos-minimal-*.iso "$isoFilePath"
sha256sum "$isoFilePath" >> "$isoFilePath".sha256
chmod 0444 "$isoFilePath".sha256

printf "\e[32m Build done...\e[0m\n"

# Pushing iso file to GitHub
gh auth status
#gh auth login --hostname github.com --git-protocol ssh --web
while true; do
read -r -p "Push ISO file to GitHub.com ? (y/n): " yn
case $yn in
  [yY] ) echo "gh release upload..."
    git push --set-upstream origin "$branch"
    gh release create "$releaseNumber" --target "$branch" --title "$releaseNumber" --prerelease --generate-notes
    gh release upload "$releaseNumber" "$isoFilePath"
    gh release upload "$releaseNumber" "$isoFilePath".sha256
    #git tag -a "$releaseNumber" -m "Release ${releaseNumber}"
    #git push --tags
    break;;
  [nN] ) echo "Proceeding without pushing...";
    break;;
  * ) echo "Invalid response";;
esac
done

printf "\e[32m All done...\e[0m\n"

#rm "$script_path"/result/

# sudo nix-store --gc

# Test it:
#qemu-system-x86_64 -enable-kvm -m 4096 -cdrom "$script_path"/curios-minimal-*.iso
