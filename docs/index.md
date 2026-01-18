# Welcome to Curi*OS* Documentation

Curi*OS* is a Linux distribution based on the [NixOS](https://nixos.org/) operating
system and the [COSMIC](https://system76.com/cosmic) desktop environment. It is
built to be modular, configurable, and securable, with a focus on providing a
tailored desktop experience. It is designed for modern, advanced users who want to
quickly achieve productivity.

Curi*OS*'s goal is to take advantage of NixOS mechanisms like declarative builds
and deployments and its unique approach to system configuration and package
management. Curi*OS* also leverages the power of the COSMIC desktop environment to
customize UX and themes.
![CuriOS desktop](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Desktop1.png?raw=true "CuriOS desktop")

## Main Goals

- **Modular Design**: Define your machine configuration as code, easily customize
your system with Nix modules.
- **Reproducible Builds**: NixOS ensures your system is always in a defined state.
- **COSMIC Desktop**: A modern and efficient desktop experience.
- **Fast Deployments**: Become operational in less than 10 minutes on your machine.

## Main Features

- 🖥️Automatic GPU hardware configuration during installation. AMD and Nvidia
GPUs are detected and corresponding drivers are installed.
- 🔐 Full disk encryption with LUKS on an LVM disk partition.
- 🌟 COSMIC, a Wayland desktop environment/window manager by System76 with
excellent window tiling management.
- 🚀 Pop_launcher: launch or switch to any desktop application with just the
Super key (Windows symbol on your keyboard, or Cmd on Apple keyboard). Forget
about your mouse; use Super key combinations for everything!
- 🔁 System packages auto-update every night or at the first boot of the day.
- 📦 More packages with Flatpak! COSMIC and Flathub repositories are pre-installed.
Packages installed from Flatpak are also auto-updated every day.
- 💻 Curi*OS* TUI Manager (shortcut: Super+Return). Manage/update/upgrade/backup
the whole system from a modern sleek Terminal User Interface.
- ⌨️ Alacritty terminal with ZSH and a lot of useful modern commands, including
⚡️ Neovim + Lazyvim pre-installed, btop, bat, duf, dust, fd, and many more...
- ✨AI tools: [LM Studio](https://lmstudio.ai/) to run local AI on your GPU
(Ollama is also easily installable). [Cursor](https://cursor.com/features) for
an AI-assisted IDE. Desktop shortcut for AI chat web applications (ChatGPT,
Claude, Grok and Mistral).
- 🐧 Uses the latest stable Linux kernel by default.
- 🗛  A bunch of nerd fonts...

## Getting Started

To get started with Curi*OS*, please refer to the [Getting Started Guide](getting-started.md).

## Explore the Curi*OS* System

You are now ready for your [first steps](first-steps.md) in the system.

## System Management / Applications

How-to:

- [Update/upgrade your system, install programs, and more](system-management.md).
- [Backup your Computer/Protect it against ransomware](backups.md)
- [Work with AI tools](ai-tools.md)

## Architecture

Learn more about the internal structure and design principles of Curi*OS* in the
[Architecture Overview](architecture.md).

## Contributing

We welcome contributions! Please refer to our [Contributing Guide](https://github.com/CuriosLabs/CuriOS/tree/master?tab=contributing-ov-file)
for details.
