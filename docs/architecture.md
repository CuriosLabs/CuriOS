# CuriOS Architecture Overview

CuriOS follows a highly modular architecture, leveraging Nix modules to define
its system configuration. This allows for a high degree of customization and
reproducibility.

## Core Technologies

* **Nix**: The primary language for all configurations, packages, and the final ISO image.
* **NixOS**: The project builds a custom version of the NixOS Linux distribution.
* **Shell**: Used for some automation tasks, like the ISO build script.

## Directory Structure

The project organizes its configurations into distinct directories:

* `iso/`: Contains files for building the bootable ISO image.
* `modules/`: The core of the project, housing Nix modules that define system configuration.
  * `desktop-apps/`: Modules for desktop applications, including web apps.
  * `filesystems/`: File system configurations, including LUKS encryption.
  * `hardened/`: Security hardening modules.
  * `hardware/`: Hardware-specific configurations (e.g., GPU drivers).
  * `platforms/`: Platform-specific configurations (e.g., `amd64`, `rpi4`).
* `pkgs/`: Custom packages built specifically for CuriOS.
* `tests/`: Integration tests using the NixOS test driver.

## Module Imports

All module imports are consolidated in `modules/default.nix`, ensuring a centralized and organized configuration management.

## Coding Style and Conventions

* **Modularity**: New features should extend existing modules or create new ones logically.
* **Descriptive Naming**: Files and modules follow consistent and descriptive naming patterns.
* **Variable Naming**: Configuration options begin with `config.curios`.
* **Code Style**: 2 spaces for indentation in Nix files.
* **Nix Formatting**: `nixfmt` is used for consistent Nix code formatting.
