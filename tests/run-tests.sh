#!/usr/bin/env bash
nix-build ./backup.nix --show-trace
nix-build ./basics-all-options.nix --show-trace
nix-build ./cosmic.nix --show-trace
nix-build ./crypto-all-options.nix --show-trace
nix-build ./curios-pkgs.nix --show-trace
nix-build ./devops-all-options.nix --show-trace
nix-build ./fonts.nix --show-trace
nix-build ./gaming-all-options.nix --show-trace
nix-build ./office-all-options.nix --show-trace
nix-build ./services-ai.nix --show-trace
nix-build ./services.nix --show-trace
nix-build ./studio-all-options.nix --show-trace
#nix repl ./basics-all-options.nix
#&& nix-instantiate ./basics-all-options.nix
rm -rf result/
