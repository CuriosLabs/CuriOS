#!/usr/bin/env bash
nix-build ./backup.nix --show-trace
nix-build ./basics.nix --show-trace
nix-build ./cosmic.nix --show-trace
nix-build ./crypto.nix --show-trace
nix-build ./curios-pkgs.nix --show-trace
nix-build ./devops.nix --show-trace
nix-build ./fonts.nix --show-trace
nix-build ./gaming.nix --show-trace
nix-build ./networking.nix --show-trace
nix-build ./office.nix --show-trace
nix-build ./services-ai.nix --show-trace
nix-build ./services.nix --show-trace
nix-build ./studio.nix --show-trace
nix-build ./virtualisation-podman.nix --show-trace
nix-build ./virtualisation.nix --show-trace
nix-build ./zsh.nix --show-trace
rm -rf result/
