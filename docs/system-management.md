# Curi*OS* Management

Curi*OS* comes with a TUI `curios-manager` (shortcut: Super+Return).

> [!NOTE]
> The **Super** key is the **Windows** key on most keyboard, the **Command** key
on Apple's keyboard.

With it, you can update/upgrade the entire system, add/remove packages (applications),
update your hardware firmware, check your disk usage, launch the process manager
(btop), and much more.

![curios-manager main menu](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_main-menu.png?raw=true "CuriOS manager main menu")

Use arrow keys to move the cursor up and down, Enter to select, and Esc to abort.

## Install/uninstall applications

You can manually edit the Curi*OS* system settings file
`/etc/nixos/settings.nix` from the `Settings (manual edit)` menu in order to add
custom Nix configuration change. It launch the system `$EDITOR` which is `nano`
by default.
![curios-manager settings screenshot](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_settingsedit3.png?raw=true "CuriOS manager settings")

Save the change on exit with `Ctrl+X`. `curios-manager` will then perform a
whole system update.

### Available Applications

For an up to date list of all pre-configured applications see the [modules README](https://github.com/CuriosLabs/CuriOS/blob/master/modules/README.md).

- **Core Apps** (Enabled by default):
  - Brave browser, Alacritty terminal, Signal, WhatsApp, VLC, Gimp3, EasyEffects.
  - Bitwarden password manager, Yubico authenticator, LocalSend file sharing.
  - Zed.dev code editor, Neovim+LazyVim terminal IDE, Cursor AI-assisted IDE.
  - AI web applications: ChatGPT, Claude, Grok, Mistral.
  - Local AI: LM Studio.
  - Project management: Basecamp.
  - Office: OnlyOffice, Obsidian, Joplin.
  - CLI: btop, nvtop, gh, fd, fzf, lazygit, ripgrep, snitch, whois, yq,
  shellcheck, statix, zsh.
  - Backup: Restic (see backups menu in `curios-manager`).

- **System Tools**: CuriOS Manager, Flatpak/Flathub apps, COSMIC store

The followings applications (packages) are available in `/etc/nixos/settings.nix`
but not installed by default, see previous chapter on how to install them.

- **Browsers**: Chromium, Firefox, LibreWolf, Vivaldi.

- **Office Apps**: LibreOffice, Thunderbird email client.

- **Project Management**: Jira web apps.

- **CRM**: Salesforce/Hubspot web apps.

- **Communication**: Slack/Teams/Zoom web apps - Discord, TeamSpeak6 desktop apps.

- **Security**: ProtonVPN, Tailscale, Mullvad VPNs, KeePassXC password manager.

- **AI Tools**: Ollama local AI, Gemini CLI, Windsurf AI-assisted IDE.

- **Development**: Go/JetBrains GoLand, Rust/JetBrains RustRover, Node.js(npm,
npx)/bun, Python/JetBrains PyCharm, Docker/Podman, lazydocker, Wine, Visual
Studio Code.

- **Virtualisation**: Qemu, KVM, virt-manager.

- **Gaming**: Steam, Steam auto-start (BigPicture mode), ProtonGE for Steam, Heroic
Launcher.

- **Specialized Apps**:
  - OBS Studio, Audacity, DaVinci Resolve, Darktable.
  - Nmap/Zenmap, Wireshark, Remmina, Cloudflared.
  - Bitcoin: Electrum/Sparrow wallets, Coingecko, Bisq2, mempool web app.

### Adding more Applications

Do you want a package not already included in one of the already pre-configured
[modules](https://github.com/CuriosLabs/CuriOS/tree/master/modules)? Add a
package found at [NixOS search packages](https://search.nixos.org/packages?sort=relevance&type=packages)?

For example, you want to install [Blender](https://www.blender.org/):

1. Launch `curios-manager` (shortcut: Super+Return)
2. Go the `Applications` menu, then `Add a new package` menu.
   ![curios-manager add package screenshot](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_addpackage1.png?raw=true "CuriOS manager add package")
3. Type an application name, the script will search for the most pertinent results.
4. Choose an application from the result list:
   ![curios-manager add package screenshot 4](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_addpackage4.png?raw=true "CuriOS manager add package 4")
5. `curios-manager` will now download and install the package.
6. Enjoy!

### Backup your computer

With `curios-manager` you can also backup your computer on a local USB drive or
a cloud-based service. See our [Backup your Computer guide](backups.md).

### System management

From `curios-manager` system menu:
![curios-manager system menu](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_system_menu.png?raw=true "curios-manager system menu")

You can shutdown/reboot/lock your computer. Manage running process on your CPU
and GPU (with `btop` and `nvtop`). See all the current network connection (with
`snitch`). You can also check your disk usage, and update your firmware (UEFI
BIOS and more).
![curios-manager system disk](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_systems_disk.png?raw=true "curios-manager system disk")
![curios-manager firmware update](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/curios-manager_system_firmware.png?raw=true "curios-manager firmware update")

## Flatpak / Desktop Apps Installation

You can also install Linux applications as Flatpaks. [Flathub](https://flathub.org/)
and COSMIC repositories come pre-installed by default. Use the "COSMIC store"
app as seen below:
![COSMIC Store screenshot](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Store.png?raw=true "COSMIC Store")

## System Upgrade

When a new version of Curi*OS* is available, you will see a pop-up appear on your
desktop:
![CuriOS updater screenshot](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Updater2.png?raw=true "CuriOS updater")

To start the system upgrade, launch `curios-manager` from a terminal (shortcut:
Super+Return) and choose the `👆Upgrade` option from the main menu.

## NixOS Management

Curi*OS* is built on top of NixOS, a Linux distribution based on the Nix
package manager and build system. It supports reproducible and declarative
system-wide configuration management, as well as atomic upgrades and rollbacks,
although it can additionally support imperative package and user management.
In NixOS, all components of the distribution—including the kernel, installed
packages, and system configuration files—are built by Nix from pure functions
called Nix expressions.
See the [NixOS manual](https://nixos.org/manual/nixos/stable/) to learn more.

The default 'configuration.nix' is set to **AUTO UPDATE** every night at 03:40
or on your first boot of the day; see `systemctl list-timers`.

Generations older than 7 days are automatically garbage collected. You can also
manually do the equivalent with:

```bash
sudo nix-collect-garbage --delete-older-than 7d &&
sudo nixos-rebuild switch --upgrade &&
sudo nixos-rebuild list-generations
```

---
**Next**: [Backup your computer](backups.md).

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md).
