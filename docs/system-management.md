# Curi*OS* Management

Curi*OS* comes with a TUI `curios-manager` (shortcut: Super+Return).
![curios-manager screenshot](https://github.com/CuriosLabs/CuriOS/blob/master/img/CuriOS-manager.png?raw=true "CuriOS manager")

With it, you can update/upgrade the entire system, update your hardware
firmware, check your disk usage, launch the process manager (btop), and much
more.

Use arrow keys to move the cursor up and down, Enter to select, and Esc to abort.

Most importantly, you can manually edit the Curi*OS* system settings file
`/etc/nixos/settings.nix` from the `System > Settings` menu.
![curios-manager settings screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settings.png?raw=true "CuriOS manager settings")

For example, do you want to game and install Steam, Heroic Launcher, Discord,
and more?

Set `gaming.enable` to `true;`, as seen below:
![curios-manager settings editor screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settingsedit.png?raw=true "CuriOS manager settings editor")
Save the change with `Ctrl+S` and exit with `Ctrl+X`. `curios-manager` will then
perform a whole system update.

Do you want a package not included in one of the already pre-configured [modules](https://github.com/CuriosLabs/CuriOS/tree/master/modules)
? Find more packages or configuration options at [NixOS packages](https://search.nixos.org/packages?channel=25.11&size=50&sort=relevance&type=packages)
and add them to `/etc/nixos/settings.nix`.

## Available Applications

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

- **Communication**: Slack/Teams/Zoom web apps.

- **Security**: ProtonVPN, Tailscale, Mullvad VPNs, KeePassXC password manager.

- **AI Tools**: Ollama local AI, Gemini CLI.

- **Development**: Go/JetBrains GoLand, Rust/JetBrains RustRover, Node.js(npm,
npx), Python/JetBrains PyCharm, Docker/Podman, lazydocker, Wine, Visual Studio Code.

- **Virtualisation**: Qemu, KVM, virt-manager.

- **Gaming**: Steam, Steam auto-start (BigPicture mode), ProtonGE for Steam,
Discord, Heroic Launcher, TeamSpeak6 client.

- **Specialized Apps**:
  - OBS Studio, Audacity, DaVinci Resolve, Darktable.
  - Nmap/Zenmap, Wireshark, Remmina, Cloudflared.
  - Bitcoin: Electrum/Sparrow wallets, Coingecko, Bisq2, mempool web app.

## Flatpak / Desktop Apps Installation

You can also install Linux applications as Flatpaks. [Flathub](https://flathub.org/)
and COSMIC repositories come pre-installed by default. Use the "COSMIC store"
app as seen below:
![COSMIC Store screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Store.png?raw=true "COSMIC Store")

## System Upgrade

When a new version of Curi*OS* is available, you will see a pop-up appear on your
desktop:
![CuriOS updater screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Updater2.png?raw=true "CuriOS updater")

To start the system upgrade, launch `curios-manager` from a terminal (shortcut:
Super+Return) and choose the `👆Upgrade` option.

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

**Next**: .

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md).
