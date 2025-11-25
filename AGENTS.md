# AGENTS.md development guide

## Directory structure

- Nix custom packages: `pkgs/`
- Nix modular configuration: `modules/`
- Import of nix module files SHOULD be done in `modules/default.nix` not in `configuration.nix`

## Coding style

- Use 2 spaces for tabulation.

## Build, Test, and Development Commands

- Lint nix files with statix: `fd ".nix" ./ | xargs -n 1 statix check`
- Lint shell scripts with shellcheck: `shellcheck --color=always -f tty -x example.sh`
