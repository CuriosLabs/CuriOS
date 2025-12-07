#!/usr/bin/env bash
nix-build ./basics-all-options.nix --show-trace
nix-build ./devops-all-options.nix --show-trace
nix-build ./gaming-all-options.nix --show-trace
nix-build ./office-all-options.nix --show-trace
nix-build ./studio-all-options.nix --show-trace
#nix repl ./basics-all-options.nix
#&& nix-instantiate ./basics-all-options.nix
rm -rf result/
