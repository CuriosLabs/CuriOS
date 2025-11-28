# AGENTS.md development guide

## Project overview

- **Project name**: CuriOS
- **Purpose**: CuriOS is a Linux distribution based on NixOS and the COSMIC desktop environment. It ships with everything a modern advanced user need to be productive as quickly as possible on his laptop / desktop.
- **Target OS**: NixOS
- **Main configuration areas**: desktop apps, networking, services.

## Directory structure

- **Nix custom packages**: Custom pkgs goes into `pkgs/` directory and should only contain a `default.nix` file like `pkgs/curios-manager/default.nix` for example.
- **Nix modular configuration**: use `modules/` directory and it's subdirectories for new modules, like `modules/desktop-apps/`, `modules/filesystems/`, `modules/hardware/` or `modules/platforms/`
- **Import of nix module**: import files SHOULD be done in `modules/default.nix` not in `configuration.nix`

## Coding style and best pratices

- **Variable naming**: config options must start with `config.curios` (e.g., `config.curios.desktop.apps.browser.chromium.enable`)
- **Code style**: Use 2 spaces for tabulation.
- **Comments**: Add a short descriptive comments to explain complex configurations.

## Build, Test, and Development Commands

- **Lint nix files**: lint with statix example:`fd ".nix" ./ | xargs -n 1 statix check`
- **Lint shell scripts**: bash script MUST be check with shellcheck: `shellcheck --color=always -f tty -x example.sh`
- **Supported version**: NixOS 25.11 or superior.
- **Test**: test custom Nix packages with: `nix-build && nix-env -i -f default.nix`

## Contributing

- **Project source**: [CuriOS github](https://github.com/CuriosLabs/CuriOS)
- **Contributing policy**: [CONTRIBUTING.md](https://raw.githubusercontent.com/CuriosLabs/CuriOS/refs/heads/release/25.11.0/CONTRIBUTING.md)
- **New feature**: Create your "feature" branch (e.g., `git checkout -b feature/AmazingFeature`) - the branch name MUST start with "feature/".
