[![NixOS 25.05](https://img.shields.io/badge/NixOS-25.05-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

# NixOS + COSMIC = Curi*OS*

This is my NixOS installer scripts and its configuration files. The desktop environment is [COSMIC](https://system76.com/cosmic/).
![Curios = NixOS + COSMIC Desktop](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Desktop.png?raw=true "NixOS with COSMIC DE - Curios")
![Curios desktop tiles](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Tiles.png?raw=true "Curios desktop tiles")


------

## Features

* 🖥️ GPU configuration files for AMD and Nvidia hardware. GPU will be detected during installation.
* 🔐 File system configuration for full encrypted disk (LUKS+LVM).
* 🌟 COSMIC, a Wayland desktop environment / windows manager by [System76](https://system76.com/cosmic/) with an excellent window's tile management.
* 🚀 Pop_launcher, launch or switch to every application just with the Super key (Windows symbol on your keyboard, or Cmd on Apple keyboard). Forget about your mouse, **use Super key combinations for everything!**
* 📦 Flatpak with **auto-update**. COSMIC and Flathub repos pre-installed.
* ⌨️ Alacritty terminal with ZSH and a lot of good modern commands. [Curi*OS* dotfiles](https://github.com/CuriosLabs/curios-dotfiles) is pre-installed.
* 📂 [Modular configuration files](https://github.com/CuriosLabs/CuriOS/tree/master/modules) for apps like Steam, Discord, OBS, Ollama AI, docker, QEMU + virt-manager, Python3, Rust and more...
* Modular hardened systemd services configurations files. -WIP-
* 🔁 NixOS packages **auto-update** every night or at first boot of the day.
* ⬆️ Curi*OS* updater. Check this GitHub repo for a new system version.
* 🐧 Use of the latest stable Linux kernel by default.
* 🗛 bunch of nerd fonts...

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
| Applications menu           | Super + A                          |
| Maximize application        | Super + M                          |
| Close application           | Super + Q                          |
| Tile mode on/off            | Super + Y                          |
| Workspaces overview         | Super + W                          |
| Lock session                | Super + Esc                        |
| Logout                      | Super + Shift + Esc                |
| Process management (btop)   | Ctrl + Alt + Del                   |

-----

> [!IMPORTANT]
> **Disclaimer:** This is a work in progress for a NixOS install and a Desktop Environment (COSMIC) still in Alpha stage.
> You should be familiar with [NixOS manual](https://nixos.org/manual/nixos/stable/) and [NixOS Wiki](https://nixos.wiki/wiki/Main_Page), for NixOS related questions go to [NixOS discourse](https://discourse.nixos.org/).

## Quick start

> [!WARNING]
> The installation script will **FORMAT** your disk !!! Backup your data before.

1. Get the latest Curi*OS* 25.05 Minimal ISO image:
   ```bash
   wget --content-disposition https://github.com/CuriosLabs/CuriOS/releases/download/25.05.2/CuriOS_25.05.2_amd64_intel.iso
   ```
   Download and check iso signature:
   ```bash
   wget --content-disposition https://github.com/CuriosLabs/CuriOS/releases/download/25.05.2/CuriOS_25.05.2_amd64_intel.iso.sha256
   sha256sum --check CuriOS_*.iso.sha256
   ```

2. Burn it on a USB stick with [Balena Etcher](https://etcher.balena.io/#download-etcher), [caligula](https://github.com/ifd3f/caligula) or the command `dd`.
   ```bash
   # Good old dd:
   sudo dd if=CuriOS_25.05.2_amd64_intel.iso of=/dev/sdb bs=10MB oflag=dsync status=progress
   # or shiny caligula:
   caligula burn -s $(cat ./CuriOS_25.05.2_amd64_intel.iso.sha256)
   ```
   Replace `/dev/sdb` with the path of the USB card (see command `sudo fdisk -l`).
3. Boot your machine on the USB stick (F8 or F12 key on startup, see your motherboard manufacturer's instructions). An internet connection is *REQUIRED* to perform the installation!
4. The installer should start automatically (otherwise launch it with `sudo curios-install`).
   ![CuriOS installation step 1](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Install_dialog_1.png?raw=true "CuriOS installation Step 1")
5. Answer the various dialog questions:
   <details>
      <summary>Click to see 'choose disk' dialog options</summary>

      ![CuriOS installation choose disk](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Install_dialog_3.png?raw=true "CuriOS install choose disk")
   </details>
   The full disk encryption option is **HIGHLY RECOMMENDED**.
   <details>
      <summary>Click to see 'full disk encryption' dialog</summary>

      ![CuriOS full disk encryption](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Install_dialog_4.png?raw=true "CuriOS full disk encryption")
   </details>
6. If everything went according to plan, reboot (and remember to remove USB media installer).
   <details>
      <summary>Click to see reboot dialog</summary>

      ![CuriOS install reboot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Install_dialog_6.png?raw=true "CuriOs installation reboot")
   </details>
7. **Enjoy!**

> [!IMPORTANT]
> Your temporary password is **"changeme"**.
> You can now change it, within COSMIC desktop: click on top right power button, then Parameters > System & Accounts > Users > "Your Account Name" > Change password.
> Or use the command `passwd` in a terminal.

-----

## Curi*OS* management

Curi*OS* come with a TUI `curios-manager` (shortcut: Super+Return).
![curios-manager screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager.png?raw=true "CuriOS manager")
With it, you can update/upgrade the whole system, update your hardware firmwares, check your disk usage, launch the process manager (btop), and much more...
But most importantly you can edit the Curi*OS* options settings from the menu `System > Settings`.
![curios-manager settings screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settings.png?raw=true "CuriOS manager settings")

For example, you want to game and install Steam, Heroic launcher, Discord and more? Set: `gaming.enable` to `true;`, as seen below:
![curios-manager settings editor screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settingsedit.png?raw=true "CuriOS manager settings editor")
Save the change with `Ctrl+S` and exit with `Ctrl+X`, `curios-manager` will then made a system update.

You want a package not in one of the already pre-configured [modules](https://github.com/CuriosLabs/CuriOS/tree/master/modules)? Find more packages or options configuration at [NixOS packages](https://search.nixos.org/packages?channel=25.05&size=50&sort=relevance&type=packages) and add it to `/etc/nixos/settings.nix`.

### System upgrade
When a new version of Curi*OS* is available, you will see a pop-up appear on your desktop:
![CuriOS updater screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Updater2.png?raw=true "CuriOS updater")

To start the system upgrade, launch `curios-manager` from a terminal (shortcut: Super+Return) and choose the `👆Upgrade` option.

### Flatpak / desktop apps installation
You can also install Linux applications as flatpak. [Flathub](https://flathub.org/) and COSMIC repositories come pre-installed by default. Use the "COSMIC store" app as seen below:
![COSMIC Store screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Store.png?raw=true "COSMIC Store")

### Dot files

[curios-dotfiles](https://github.com/CuriosLabs/curios-dotfiles) come pre-installed with my COSMIC theme (WIP) and for a nice Alacritty and ZSH integration.
![Curios dotfiles](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Terminal.png?raw=true "Curios dotfiles")

-----

## NixOS management

Curi*OS* is build on top of NixOS, a Linux distribution based on the Nix package manager and build system. It supports reproducible and declarative system-wide configuration management as well as atomic upgrades and rollbacks, although it can additionally support imperative package and user management. In NixOS, all components of the distribution — including the kernel, installed packages and system configuration files — are built by Nix from pure functions called Nix expressions.
See [NixOS manual](https://nixos.org/manual/nixos/stable/) to learn more.

The default 'configuration.nix' is set to **AUTO UPDATE** every night at 03:40 or on your first boot of the day, see `systemctl list-timers`.

Generations older than 7 days are automatically garbage collected. You can also manually do the equivalent with:
```bash
sudo nix-collect-garbage --delete-older-than 7d && sudo nixos-rebuild switch --upgrade && sudo nixos-rebuild list-generations
```

-----

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

-----

## Version

The current version is [25.05.2](https://github.com/CuriosLabs/CuriOS/tree/release/25.05.2) based on a Nixos 25.05 build.

-----

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

## Sources
[Cosmic desktop](https://github.com/pop-os/cosmic-epoch) by system76.
Hardened configuration files by [wallago](https://github.com/wallago/nix-system-services-hardened).
