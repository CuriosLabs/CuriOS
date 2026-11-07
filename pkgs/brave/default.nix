# Brave browser.
# Dropped from nixpkgs on 2026-11-06 (no maintainer with committer rights):
# https://discourse.nixos.org/t/brave-browser-has-been-dropped/81004
# This package continues the former nixpkgs package from the community flake:
# https://codeberg.org/buckley310/brave-browser-nix
# It repackages the pre-built upstream binaries (no source rebuild).
#
# The source follows the flake's main branch (like a channel): Brave updates
# published upstream are picked up automatically on the next rebuild, no manual
# pin bump needed. The package is built with OUR nixpkgs (equivalent of the
# flake input "inputs.nixpkgs.follows = nixpkgs" from the flake README).
# Note: following a branch requires impure evaluation (default for
# nixos-rebuild / nix-build). To lock a specific revision instead, add:
#   rev = "<commit-sha>";
{ callPackage, ... }:

let
  braveFlake = builtins.fetchGit {
    url = "https://codeberg.org/buckley310/brave-browser-nix";
    ref = "main";
  };
in
(callPackage "${braveFlake}/brave" { }).brave
