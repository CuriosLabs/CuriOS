# Curi*OS*

[![NixOS 25.11](https://img.shields.io/badge/NixOS-25.11-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)
[![X Follow](https://img.shields.io/twitter/follow/CuriosLabs?style=social)](https://x.com/CuriosLabs)

Curi*OS* is a Linux distribution based on [NixOS](https://nixos.org/) and the
[COSMIC](https://system76.com/cosmic) desktop environment. It ships with
everything a modern advanced user need to be productive as quickly as possible
on his laptop / desktop.
Curi*OS* goal is to take advantage of NixOS mechanisms like declarative builds
and deployments and its unique approach to system configuration and package
management. Curi*OS* also take advantage of COSMIC power to customize UX and theme.

> [!IMPORTANT]
> **Disclaimer:** This is a work in progress for a NixOS customized install.
> Development should be considered at a Beta stage.
> You should be familiar with [NixOS manual](https://nixos.org/manual/nixos/stable/)
> and [NixOS Wiki](https://nixos.wiki/wiki/Main_Page), for NixOS related questions
> go to [NixOS discourse](https://discourse.nixos.org/).

![Curios = NixOS + COSMIC Desktop](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Desktop.png?raw=true "NixOS with COSMIC DE - Curios")
![Curios desktop tiles](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Tiles.png?raw=true "Curios desktop tiles")

## Features

* 🖥️ GPU configuration files for AMD and Nvidia hardware. GPU will be
detected during installation.
* 🔐 File system configuration for full encrypted disk (LUKS+LVM).
* 🌟 COSMIC, a Wayland desktop environment / windows manager by
[System76](https://system76.com/cosmic/) with an excellent window's tile management.
* 🚀 Pop_launcher, launch or switch to every application just with the Super
key (Windows symbol on your keyboard, or Cmd on Apple keyboard). Forget about
your mouse, **use Super key combinations for everything!**
* 📦 Flatpak with **auto-update**. COSMIC and Flathub repos pre-installed.
* 💻 Curi*OS* TUI manager (shortcut: Super+Return). Manage/update/upgrade/backup
the whole system from a modern sleek Terminal User Interface.
* ⌨️ Alacritty terminal with ZSH and a lot of good modern commands.
[Curi*OS* dotfiles](https://github.com/CuriosLabs/curios-dotfiles) is pre-installed.
* ⚡️ Neovim + LazyVim plugin with starter configuration.
* ✨AI tools: [LM Studio](https://lmstudio.ai/) to run local AI on your GPU
(Ollama is also easily installable). [Cursor](https://cursor.com/features) for
an AI-assisted IDE. Desktop shortcut for AI chat web applications (ChatGPT,
Claude, Grok and Mistral).
* 📂 [Modular configuration files](https://github.com/CuriosLabs/CuriOS/tree/master/modules)
for apps like Steam, Discord, OBS, Ollama AI, docker, QEMU + virt-manager,
Python3, Rust and more...
* Modular hardened systemd services configurations files. -WIP-
* 🔁 NixOS packages **auto-update** every night or at first boot of the day.
* ⬆️ Curi*OS* updater. Automatically check this GitHub repo for a new system version.
* 🐧 Use of the latest stable Linux kernel by default.
* 🗛 bunch of nerd fonts...

## Quick start / installation guide

See our [getting started guide](https://github.com/CuriosLabs/CuriOS/blob/master/docs/getting-started.md)
on how to install Curi*OS*.

## Documentation

Visit our [documentation here](https://github.com/CuriosLabs/CuriOS/blob/master/docs/index.md).

## System Management / Applications

How-to:

* [Do your first steps](https://github.com/CuriosLabs/CuriOS/blob/master/docs/first-steps.md).
* [Update/upgrade your system, install programs, and more](https://github.com/CuriosLabs/CuriOS/blob/master/docs/system-management.md).
* [Backup your Computer](https://github.com/CuriosLabs/CuriOS/blob/master/docs/backups.md)
* [Work with AI tools](https://github.com/CuriosLabs/CuriOS/blob/master/docs/ai-tools.md)

### Dot files / Theme

[curios-dotfiles](https://github.com/CuriosLabs/curios-dotfiles) come pre-
installed with my COSMIC theme (WIP) and for a nice Alacritty and ZSH integration.
![Curios dotfiles](https://github.com/CuriosLabs/CuriOS/blob/testing/img/DesktopTUI2.png?raw=true "Curios dotfiles")

## Contributing

Contributions are what make the open source community such an amazing place to
learn, inspire, and create. Any contributions you make are **greatly appreciated**.

See [Contributing instructions here](https://github.com/CuriosLabs/CuriOS/tree/master?tab=contributing-ov-file).

## Version

The current version is [25.11.3](https://github.com/CuriosLabs/CuriOS/tree/release/25.11.3)
based on a Nixos 25.11 build.

## License

Copyright (C) 2025  David BASTIEN

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Notice

All product names, trademarks, and registered trademarks are the property of
their respective owners. Icons are used for identification purposes only and
do not imply endorsement.

## Sources

[Cosmic desktop](https://github.com/pop-os/cosmic-epoch) by system76.
Hardened configuration files by [wallago](https://github.com/wallago/nix-system-services-hardened).
