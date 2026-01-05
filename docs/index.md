# Welcome to Curi*OS* Documentation

Curi*OS* is a Linux distribution based on [NixOS](https://nixos.org/) operating
system and the [COSMIC](https://system76.com/cosmic) desktop environment. It is
build to be modular, configurable, and securable, with a focus on providing a
tailored desktop experience. It is built for modern, advanced users who want to
quickly achieve productivity.

Curi*OS* goal is to take advantage of NixOS mechanisms like declarative builds
and deployments and its unique approach to system configuration and package
management. Curi*OS* also take advantage of COSMIC desktop environment power to
customize UX and custom themes.
![CuriOS desktop](https://github.com/CuriosLabs/CuriOS/blob/master/img/Desktop1.png "CuriOS desktop")

## Main goals

- **Modular Design**: Define your machine configuration as code, easily customize
your system with Nix modules.
- **Reproducible Builds**: NixOS ensures your system is always in a defined state.
- **COSMIC Desktop**: A modern and efficient desktop experience.
- **Fast deployments**: Become operational in less than 10 minutes on your machine.

## Main features

- 🖥️Automatic GPU hardware configuration during installation. AMD and Nvidia
GPUs are detected and corresponding pilots installed.
- 🔐 Full disk encryption with LUKS on an LVM disk partition.
- 🌟 COSMIC, a Wayland desktop environment / windows manager by System76 with
an excellent window's tile management.
- 🚀 Pop_launcher, launch or switch to every desktop applications just with the
Super key (Windows symbol on your keyboard, or Cmd on Apple keyboard). Forget
about your mouse, use Super key combinations for everything!
- 🔁 System packages auto-update every night or at first boot of the day.
- 📦 More packages with Flatpak! COSMIC and Flathub repos pre-installed.
Packages installed from Flatpak are also auto-updated every day.
- 💻 Curi*OS* TUI manager (shortcut: Super+Return). Manage/update/upgrade/backup
the whole system from a modern TUI.
- ⌨️ Alacritty terminal with ZSH and a lot of good modern commands, including
⚡️ Neovim + Lazyvim pre-installed, btop, bat, duf, dust, fd and many more...
- 🐧 Use of the latest stable Linux kernel by default.
- 🗛  bunch of nerd fonts...

## Getting Started

To get started with Curi*OS*, please refer to the [Getting Started Guide](getting-started.md).

## Explore the Curi*OS* system

You are now ready for your [first steps](first-steps.md) in the system.

## Applications

TBD.

## Architecture

Learn more about the internal structure and design principles of Curi*OS* in the
[Architecture Overview](architecture.md).

## Contributing

We welcome contributions! Please refer to our [Contributing Guide](https://github.com/CuriosLabs/CuriOS/tree/master?tab=contributing-ov-file)
for details.
