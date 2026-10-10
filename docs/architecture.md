# Curi*OS* Architecture Overview

Curi*OS* is a Linux distribution built on top of [NixOS](https://nixos.org/) and
the [COSMIC](https://system76.com/cosmic) desktop environment. It is designed
for modern, advanced users who want to be productive quickly, combining the
reproducibility of NixOS with a polished, opinionated desktop experience.

## What Makes Curi*OS* Different

Unlike traditional Linux distributions where system configuration is scattered
across `/etc/`, package installations are imperative, and upgrades can break
your system, Curi*OS* takes a fundamentally different approach:

- **Declarative Everything**: Your entire system—kernel, packages, services,
  desktop settings—is defined as code in Nix expressions. The system is always
  in a known, reproducible state.
- **Atomic Upgrades & Rollbacks**: System updates are atomic. If something goes
  wrong, you can boot into a previous generation instantly.
- **Modular by Design**: Applications and features are organized into
  toggleable modules (e.g., `curios.desktop.browser.firefox.enable`). Enable or
  disable features with a single command or through the TUI manager.
- **Three-Layer Configuration**: The system separates distribution defaults
  from user customizations. Only three files survive upgrades:
  `modules.json` (module settings, with `.bak` backups), `settings.nix`
  (personal customizations), and `hardware-configuration.nix` (hardware
  detection). Everything else is overwritten.
- **Integrated Tooling**: Curi*OS* ships with dedicated CLI tools
  (`curios-update`, `curios-dotfiles`) and a TUI manager (`curios-manager`) that
  make system administration accessible without memorizing NixOS commands.
- **COSMIC Desktop**: A modern Wayland desktop environment by System76 with
  excellent tiling window management, theming support, and a cohesive design
  language.
- **Security-First**: Full-disk encryption with LUKS, YubiKey support for login
  and disk decryption, AppArmor profiles, and Secure Boot support are built-in.

## Core Technologies

- **Nix**: The functional package manager and build system. All packages,
  configurations, and the ISO image are built using the Nix language.
- **NixOS**: The base Linux distribution. Curi*OS* is a specialized NixOS
  configuration, not a fork.
- **Nix Flakes**: Used for reproducible dependency management and system
  builds.
- **COSMIC**: The desktop environment, providing the window manager, panel,
  settings, and default applications.
- **Just**: A command runner used for development tasks (build, test, lint).

## System Management Tools

Curi*OS* provides three main interfaces for managing the system:

### `curios-manager` (TUI)

A terminal user interface launched with `Super+Return`. From here you can:

- Update and upgrade the system
- Install/uninstall applications (CuriOS modules and NixOS packages)
- Manage Flatpak applications
- Backup your computer
- Update hardware firmware
- Monitor system resources (disk, CPU, GPU, network)
- Change desktop themes
- Enroll YubiKey for authentication
- Enable Secure Boot and AppArmor
- Edit system settings manually

### `curios-update` (CLI)

A command-line tool for system-level operations: update/upgrade the system,
search and install packages, manage CuriOS modules, and query NixOS options.

See [System Management](system-management.md#command-line-tools) for detailed
command examples.

### `curios-dotfiles` (CLI)

Manages desktop themes, wallpapers, and dotfiles.

See [System Management](system-management.md#command-line-tools) for detailed
command examples.

Themes are defined in `~/.curios/themes/themes.json` and configure the
appearance of COSMIC desktop, Alacritty/Ghostty terminals, Neovim, Zed editor,
and the Brave browser. Wallpapers are stored in `~/.curios/wallpapers/`.

Themes and dotfiles are sourced from a Git repository. The default source is
`https://github.com/CuriosLabs/curios-themes`. Advanced users can use their own
themes and dotfiles from any valid Git URL by changing the options
`curios.core.dotfiles.url` and `curios.core.dotfiles.branch`.

## Update & Upgrade Workflow

Curi*OS* follows a Git-based update model:

- **Update** (`curios-update --update`): Updates all Nix packages and flakes,
  runs garbage collection, and warns if a reboot is needed. This is safe to
  run anytime.
- **Upgrade** (`curios-update --upgrade`): Clones the CuriOS source repository
  and installs the latest version. The repository URL and branch are
  configurable via `curios.core.source.url` and `curios.core.source.branch`.

### Commit Signature Verification

For security, Curi*OS* verifies the SSH signature of the latest commit during
an upgrade. If the commit is **not signed** with the official CuriosLabs SSH
key, the upgrade is **aborted**. This protects against supply-chain attacks in
case the GitHub repository is compromised.

Available branches:

- `stable` (default): Production-ready releases.
- `testing`: For developers contributing to CuriOS.
- `unstable`: Follows NixOS unstable channel. May break; use with caution.

Automatic updates run nightly or at first boot of the day.

## The Module System

Curi*OS* organizes features into **modules**—self-contained Nix configurations
that can be enabled or disabled. Modules are declared with options following the
`config.curios.*` namespace:

```nix
config.curios.desktop.browser.firefox.enable = true;
config.curios.system.timeZone = "Europe/Berlin";
config.curios.hardware.nvidiaGpu.enable = true;
```

Modules are stored in `/etc/nixos/modules.json` and can be managed via:

- The TUI (`curios-manager` → Applications)
- The CLI (`curios-update --update-module <key> <value>`)
- Direct JSON editing (advanced users)

### Module Categories

- **Desktop Applications** (`modules/desktop-apps/`): Browsers, office suites,
  media players, AI tools, development tools, gaming, and more. Includes both
  native desktop apps and web app shortcuts (e.g., ChatGPT, Claude).
- **Filesystems** (`modules/filesystems/`): Disk partitioning and LUKS
  encryption configurations.
- **Hardware** (`modules/hardware/`): GPU drivers (AMD, NVIDIA, Intel) and
  platform-specific settings.
- **Hardened** (`modules/hardened/`): Security hardening profiles.
- **Platforms** (`modules/platforms/`): Architecture-specific configurations
  (amd64, rpi4).

## File and Directory Structure

### On an Installed System (`/etc/nixos/`)

| File | Purpose | Preserved across upgrades? |
|------|---------|---------------------------|
| `configuration.nix` | Main NixOS configuration, imports all modules | **No** (overwritten) |
| `hardware-configuration.nix` | Hardware-specific settings generated during install | **Yes** |
| `modules.json` | Enabled CuriOS modules and their settings | **Yes** (backed up as `modules.json.*.bak`) |
| `modules.json.*.bak` | Automatic backups of `modules.json` | **Yes** |
| `settings.nix` | User customizations: extra packages, NixOS options | **Yes** |
| `docs/` | Offline copy of Curi*OS* documentation | No |

> **Important**: Only `settings.nix`, `modules.json` (and its `.bak` backups),
> and `hardware-configuration.nix` survive system upgrades. Never edit other
> files under `/etc/nixos/` directly—they will be overwritten.

`modules.json` is modified by `sudo curios-update --update-module <key> <value>`
and preserved (with timestamped `.bak` backups) across upgrades.

### In the Source Repository

- `docs/`: Official documentation in Markdown format.
- `iso/`: Files for building the bootable ISO image.
- `modules/`: Core Nix modules defining the system configuration.
  - `default.nix`: Imports all sub-modules.
  - `desktop-apps/`: Desktop and web application modules.
  - `filesystems/`: File system and encryption configurations.
  - `hardened/`: Security hardening modules.
  - `hardware/`: Hardware-specific configurations (GPU drivers).
- `pkgs/`: Custom packages built specifically for Curi*OS* (e.g.,
  `curios-manager`, `curios-update`, `curios-dotfiles`).
- `tests/`: NixOS integration tests running in QEMU VMs.
- `configuration.nix`: Template for the main system configuration.
- `curios-install`: Installation script run from the ISO.
- `justfile`: Development command definitions.

## Configuration Philosophy

Curi*OS* uses a **layered configuration** approach:

1. **Base Layer** (read-only): The Curi*OS* distribution defaults, defined in
   the source repository's Nix modules. Overwritten on every upgrade.
2. **Module Layer** (`modules.json`): Which CuriOS modules are enabled and
   their settings. Managed via `curios-update --update-module` or the TUI.
   Preserved across upgrades with automatic `.bak` backups.
3. **User Layer** (`settings.nix`): Personal customizations—extra packages,
   users, network settings, NixOS options. Preserved across upgrades.
4. **Hardware Layer** (`hardware-configuration.nix`): Auto-generated hardware
   configuration (disk partitions, kernel modules). Preserved across upgrades.

This separation means:

- Upgrades bring new features and fixes without losing your customizations.
- You can experiment freely; rollback is always possible.
- The system remains reproducible—your configuration is code.

## Package Management Hierarchy

When installing software, Curi*OS* follows this priority:

1. **CuriOS Module**: Check if the app is available as a pre-configured module
   (`curios-update --search-modules <name>`). Modules come with sensible
   defaults and integration.
2. **NixOS Package**: Search the NixOS package repository
   (`curios-update --search-pkgs <name>`) and install via
   `curios-update --add-pkg`.
3. **Flatpak**: For apps not in NixOS, use Flatpak. Flathub and COSMIC
   repositories are pre-configured. Install via `flatpak install flathub <id>`
   or the COSMIC Store GUI.

## Reproducibility & Generations

Every system change creates a new **generation**—a complete, bootable snapshot
of your system. NixOS keeps previous generations, allowing instant rollback:

```bash
# List available generations
nixos-rebuild list-generations

# Roll back at boot time (select from the boot menu)
# Or switch to a previous generation:
sudo nixos-rebuild switch --rollback
```

Generations older than 15 days are automatically garbage-collected.

---

**Next**: [Development guide of CuriOS](development.md).

**Previous**: [Virtualisation applications](virtualisation.md)

**Back**: [index](index.md).
