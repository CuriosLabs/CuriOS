# Curi*OS* Architecture Overview

Curi*OS* follows a highly modular architecture, leveraging Nix modules to define
its system configuration. This allows for a high degree of customization and
reproducibility.

## Core Technologies

- **Nix**: The primary language for all configurations, packages, and the final
  ISO image.
- **NixOS**: The project builds a custom version of the NixOS Linux distribution.
- **Shell**: Used for some automation tasks, such as the ISO build script.

## Directory Structure

The project's configuration is organized into the following directories:

- `iso/`: Contains files for building the bootable ISO image.
- `modules/`: The core of the project, which houses Nix modules that define the
  system configuration.
  - `desktop-apps/`: Modules for desktop and web applications.
  - `filesystems/`: File system configurations, including options for LUKS encryption.
  - `hardened/`: Modules for security hardening.
  - `hardware/`: Hardware-specific configurations (e.g., for GPU drivers).
  - `platforms/`: Platform-specific configurations (e.g., for `amd64` and `rpi4`).
- `pkgs/`: Custom packages built specifically for Curi*OS*.
- `tests/`: Integration tests that use the NixOS test driver.

## Module Imports

All module imports are consolidated in `modules/default.nix` for centralized and
organized configuration management.

## Coding Style and Conventions

- **Modularity**: New features should extend existing modules or be created as
  new, logically named modules.
- **Descriptive Naming**: Files and modules follow consistent and descriptive
  naming patterns.
- **Variable Naming**: Configuration options start with `config.curios`.
- **Code Style**: Use 2 spaces for indentation in Nix files.
- **Nix Formatting**: `nixfmt` is used for consistent Nix code formatting.

**Back**: [index](index.md).
