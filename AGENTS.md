# CuriOS Development Guide

This guide provides instructions and best practices for developers contributing to the CuriOS project.

## Project Overview

- **Project Name**: CuriOS
- **Purpose**: A Linux distribution based on NixOS and the COSMIC desktop environment, designed for modern advanced users to be productive quickly.
- **Target OS**: NixOS
- **Main Configuration Areas**: Desktop apps, networking, services.

## Directory Structure

- **Nix Custom Packages**: Custom packages should be placed in the `pkgs/` directory, with each package having its own `default.nix` file (e.g., `pkgs/curios-manager/default.nix`).
- **Nix Modular Configuration**: New modules should be placed in the `modules/` directory and its subdirectories (e.g., `modules/desktop-apps/`, `modules/filesystems/`, `modules/hardware/`, `modules/platforms/`).
- **Module Imports**: All module imports should be done in `modules/default.nix`, not in `configuration.nix`.

## Coding Style and Best Practices

- **Variable Naming**: Configuration options must start with `config.curios` (e.g., `config.curios.desktop.apps.browser.chromium.enable`).
- **Code Style**: Use 2 spaces for indentation in Nix files.
- **Comments**: Add short, descriptive comments to explain complex configurations.

## Build, Test, and Development Commands

- **Lint Nix Files**: Lint Nix files using `statix`. You can use `fd` to find all `.nix` files:
  ```bash
  fd ".nix" . | xargs -n 1 statix check
  ```
  If you don't have `fd` installed, you can use `find`:
  ```bash
  find . -name "*.nix" -print0 | xargs -0 -n 1 statix check
  ```
- **Lint Shell Scripts**: Shell scripts must be checked with `shellcheck`:
  ```bash
  shellcheck --color=always -f tty -x your_script.sh
  ```
- **Supported Version**: NixOS 25.11 or later.
- **Test Custom Packages**: Test custom Nix packages with:
  ```bash
  nix-build && nix-env -i -f default.nix
  ```

## Contributing

- **Project Source**: [CuriOS GitHub](https://github.com/CuriosLabs/CuriOS)
- **Contributing Policy**: See [CONTRIBUTING.md](https://raw.githubusercontent.com/CuriosLabs/CuriOS/refs/heads/release/25.11.0/CONTRIBUTING.md).
- **Branching Strategy**: For new features, create a branch named `feature/<YourFeatureName>` (e.g., `git checkout -b feature/AmazingFeature`).
