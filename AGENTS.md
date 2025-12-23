# CuriOS Development Guide

This guide provides instructions and best practices for developers contributing
to the CuriOS project.

## Context

You are an expert software architect and project analysis assistant. Analyze
the current project directory and help developers that interacts with this
project. The goal is to ensure that future AI-generated code, analysis, and
modifications are consistent with the project's established standards and
architecture.

## Project Overview

- **Project Name**: CuriOS
- **Purpose**: A Linux distribution based on NixOS and the COSMIC desktop
environment, designed for modern advanced users to be productive quickly.
- **Target OS**: NixOS
- **Main Configuration Areas**: Desktop apps, networking, services.

## Core Technologies

* **Nix:** The primary language used in this project is Nix. All configurations
, packages, and the final ISO image are defined using the Nix language.
* **NixOS:** The project builds a custom version of the NixOS Linux distribution.
* **Shell:** The project uses shell scripts for some automation tasks, such as
the ISO build script.

## Directory Structure

The project follows a modular architecture, with different aspects of the system
configuration separated into distinct Nix modules. The main directories are:

- `iso/`: Contains the files for building the bootable ISO image.
- `modules/`: The core of the project, containing the Nix modules that define
the system configuration.
  - `desktop-apps/`: Modules for installing and configuring desktop applications
  including web apps.
  - `filesystems/`: Modules for configuring file systems, including options for
  LUKS encryption.
  - `hardened/`: Modules for applying security hardening to the system.
  - `hardware/`: Hardware-specific configurations, such as GPU drivers.
  - `platforms/`: Platform-specific configurations, like for `amd64` and `rpi4`.
- `pkgs/`: Contains custom packages built for CuriOS, with each package
having its own `default.nix` file (e.g., `pkgs/curios-manager/default.nix`).
- **Module Imports**: All module imports should be done in `modules/default.nix`
not in `configuration.nix`.

## Key Files

- `configuration.nix`: The main NixOS configuration file for a CuriOS system.
- `settings.nix`: A file for user-specific settings, which is imported into the
main configuration.
- `iso/iso-minimal.nix`: The Nix expression that defines the contents and
configuration of the bootable ISO image.
- `modules/default.nix`: The top-level module that imports all other modules in
the `modules/` directory.
- `curios-install`: A script for installing CuriOS to a target system.

## Coding Style and Best Practices

- **Modularity:** The project is highly modular. When adding new features,
it's important to create new modules or extend existing ones in a logical and
organized manner.
- **Descriptive Naming:** File and module names are descriptive and follow a
consistent pattern (e.g., `filesystems-luks-v2.nix`, `webapp-chatgpt.nix`).
- **Variable Naming**: Configuration options must start with `config.curios`
(e.g., `config.curios.desktop.apps.browser.chromium.enable`).
- **Code Style**: Use 2 spaces for indentation in Nix files.
- **Nix formatting**: Use `nixfmt` the official formatter for Nix code.
- **Comments**: The code is sparsely commented. When adding new code, add
comments only when necessary to explain complex logic.

## Build, Test, and Development Commands

- **Lint Nix Files**: Lint Nix files using `statix`. You can use `fd` to find
all `.nix` files:

  ```bash
  fd ".nix" . | xargs -n 1 statix check
  ```

  If you don't have `fd` installed, you can use `find`:

  ```bash
  find . -name "*.nix" -print0 | xargs -0 -n 1 statix check
  ```

- **Lint Shell Scripts**: Shell scripts must be checked with `shellcheck`:

  ```bash
  shellcheck --color=always -f tty -x ./curios-install ./iso/build.sh
  ```

- **Supported Version**: NixOS 25.11 or later.
- **Test Custom Packages**: Test custom Nix packages with:

  ```bash
  nix-build && nix-env -i -f default.nix
  ```

- **Test NixOS Modules**: CuriOS uses the built-in NixOS test driver to run
integration tests in a virtual machine. Test files are located in the `tests/`
directory.

  To run a specific test (e.g., the office desktop apps):
  
  ```bash
  nix-build ./tests/office.nix --show-trace
  ```

  This command will build a minimal NixOS system in a QEMU virtual machine,
  boot it, and execute the test script defined in the file.

  **Important**: Running tests will create many files in `/nix/store`. After
  you are finished with testing, run `nix-collect-garbage -d` to clean up the
  build artifacts and reclaim disk space.

- Analyze: Get latest code changes from git:

  ```bash
  git log
  ```

## Contributing

- **Project Source**: [CuriOS GitHub](https://github.com/CuriosLabs/CuriOS)
- **Contributing Policy**: See @CONTRIBUTING.md
- **Branching Strategy**: For new features, create a branch named
`feature/<YourFeatureName>` (e.g., `git checkout -b feature/AmazingFeature`).
