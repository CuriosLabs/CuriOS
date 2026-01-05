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
the whole system from a modern TUI.
* ⌨️ Alacritty terminal with ZSH and a lot of good modern commands.
[Curi*OS* dotfiles](https://github.com/CuriosLabs/curios-dotfiles) is pre-installed.
* ⚡️ Neovim + LazyVim plugin with starter configuration.
* 📂 [Modular configuration files](https://github.com/CuriosLabs/CuriOS/tree/master/modules)
for apps like Steam, Discord, OBS, Ollama AI, docker, QEMU + virt-manager,
Python3, Rust and more...
* Modular hardened systemd services configurations files. -WIP-
* 🔁 NixOS packages **auto-update** every night or at first boot of the day.
* ⬆️ Curi*OS* updater. Check this GitHub repo for a new system version.
* 🐧 Use of the latest stable Linux kernel by default.
* 🗛 bunch of nerd fonts...

## Quick start

See our [getting started guide](https://github.com/CuriosLabs/CuriOS/blob/master/docs/getting-started.md).

## First steps

Most useful desktop shortcuts:

| **Action**                  | Shortcut (Super=Windows key)       |
|-----------------------------|------------------------------------|
| Application launcher/switch | Super                              |
| Curi*OS* manager            | Super + Return                     |
| Change application focus    | Super + Up/Down/Left/Right         |
| Switch desktop              | Super + Ctrl + Up/Down             |
| Move application (tiles)    | Super + Shift + Up/Down/Left/Right |
| Launch web browser          | Super + B                          |
| Launch File manager         | Super + F                          |
| Launch a terminal           | Super + T                          |

See more at our [first steps guide](https://github.com/CuriosLabs/CuriOS/blob/master/docs/first-steps.md).

## Curi*OS* management

Curi*OS* come with a TUI `curios-manager` (shortcut: Super+Return).
![curios-manager screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager.png?raw=true "CuriOS manager")
With it, you can update/upgrade the whole system, update your hardware firmware
, check your disk usage, launch the process manager (btop), and much more...
But most importantly you can edit the Curi*OS* options settings from the menu
`System > Settings`.
![curios-manager settings screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settings.png?raw=true "CuriOS manager settings")

For example, you want to game and install Steam, Heroic launcher, Discord and
more? Set: `gaming.enable` to `true;`, as seen below:
![curios-manager settings editor screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settingsedit.png?raw=true "CuriOS manager settings editor")
Save the change with `Ctrl+S` and exit with `Ctrl+X`, `curios-manager` will
then made a system update.

You want a package not in one of the already pre-configured [modules](https://github.com/CuriosLabs/CuriOS/tree/master/modules)
? Find more packages or options configuration at [NixOS packages](https://search.nixos.org/packages?channel=25.11&size=50&sort=relevance&type=packages)
and add it to `/etc/nixos/settings.nix`.

### System upgrade

When a new version of Curi*OS* is available, you will see a pop-up appear on
your desktop:
![CuriOS updater screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Updater2.png?raw=true "CuriOS updater")

To start the system upgrade, launch `curios-manager` from a terminal (shortcut:
Super+Return) and choose the `👆Upgrade` option.

### Flatpak / desktop apps installation

You can also install Linux applications as flatpak. [Flathub](https://flathub.org/)
and COSMIC repositories come pre-installed by default. Use the "COSMIC store"
app as seen below:
![COSMIC Store screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Store.png?raw=true "COSMIC Store")

### Dot files

[curios-dotfiles](https://github.com/CuriosLabs/curios-dotfiles) come pre-
installed with my COSMIC theme (WIP) and for a nice Alacritty and ZSH integration.
![Curios dotfiles](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Terminal.png?raw=true "Curios dotfiles")

## NixOS management

Curi*OS* is build on top of NixOS, a Linux distribution based on the Nix
package manager and build system. It supports reproducible and declarative
system-wide configuration management as well as atomic upgrades and rollbacks,
although it can additionally support imperative package and user management.
In NixOS, all components of the distribution — including the kernel, installed
packages and system configuration files — are built by Nix from pure functions
called Nix expressions.
See [NixOS manual](https://nixos.org/manual/nixos/stable/) to learn more.

The default 'configuration.nix' is set to **AUTO UPDATE** every night at 03:40
or on your first boot of the day, see `systemctl list-timers`.

Generations older than 7 days are automatically garbage collected. You can also
manually do the equivalent with:

```bash
sudo nix-collect-garbage --delete-older-than 7d &&
sudo nixos-rebuild switch --upgrade &&
sudo nixos-rebuild list-generations
```

## Contributing

Contributions are what make the open source community such an amazing place to
learn, inspire, and create. Any contributions you make are **greatly appreciated**.

See [Contributing instructions here](https://github.com/CuriosLabs/CuriOS/tree/master?tab=contributing-ov-file).

## Version

The current version is [25.11.1](https://github.com/CuriosLabs/CuriOS/tree/release/25.11.1)
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
