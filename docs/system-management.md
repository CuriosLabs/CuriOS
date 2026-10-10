# Curi*OS* Management

Curi*OS* comes with a TUI `curios-manager` (shortcut: Super+Return).

> [!NOTE]
> The **Super** key is the **Windows** key on most keyboard, the **Command** key
on Apple's keyboard.

With it, you can update/upgrade the entire system, add/remove packages (applications),
update your hardware firmware, check your disk usage, launch the process manager
(btop), and much more.

![curios-manager main menu](https://github.com/CuriosLabs/CuriOS/blob/release/26.05.10/img/curios-manager_main-menu2.png?raw=true "CuriOS manager main menu")

Use arrow keys to move the cursor up and down, Enter to select, and Esc to abort.

## Install/uninstall applications

### Available Applications as CuriOS modules

CuriOS comes with pre-configured and pre-installed applications known as "modules".
To install or uninstall one of these modules:

1. Launch `curios-manager` (shortcut: Super+Return)
2. Go to the `Applications` menu, then `Install/uninstall CuriOS Apps` menu.
3. Search for an application or module. Enabled applications appear in green.
4. Use the space bar or the X key to toggle an application, Enter key to submit
   or Esc to abort.
   ![curios-manager modules menu](https://github.com/CuriosLabs/CuriOS/blob/master/img/curios-manager_modulesmenu.png?raw=true "CuriOS manager modules menu")
5. If you made any change `curios-manager` will update your system.

For an up to date list of all the CuriOS modules see the [modules.json](https://github.com/CuriosLabs/CuriOS/blob/master/modules.json)
file.

- **Core Apps** (Enabled by default):
  - Brave browser, Alacritty terminal, Signal, WhatsApp, VLC, Gimp3, EasyEffects.
  - Bitwarden password manager, Yubico authenticator, LocalSend file sharing.
  - OpenCode desktop and TUI, Zed.dev code editor, Neovim+LazyVim terminal IDE,
    Cursor AI-assisted IDE.
  - AI web applications: ChatGPT, Claude, Grok, Mistral.
  - Project management: Basecamp.
  - Office: Obsidian, Joplin.
  - Terminal: Alacritty.
  - CLI: btop, nvtop, gh, fd, fzf, lazygit, ripgrep, snitch, whois, yq,
  shellcheck, statix, zsh.
  - Backup: Restic (see backups menu in `curios-manager`).

- **System Tools**: CuriOS Manager, Flatpak/Flathub apps, COSMIC store

The following applications (packages) are available but not installed by default;
see the previous section on how to install them.

- **Browsers**: Chromium, Firefox, LibreWolf, Vivaldi.

- **Office Apps**: OnlyOffice, LibreOffice, Thunderbird email client.

- **Project Management**: Jira web apps.

- **CRM**: Salesforce/Hubspot web apps.

- **Communication**: Slack/Teams/Zoom web apps - Discord, TeamSpeak6 desktop apps.

- **Security**: ProtonVPN, Tailscale, Mullvad VPNs, KeePassXC password manager.

- **AI Tools**: LM Studio / Bionic, Ollama local AI.

- **Development**: Go/JetBrains GoLand, Rust/JetBrains RustRover, Node.js(npm,
npx)/bun, Python/JetBrains PyCharm, Docker/Podman, lazydocker, Wine, Visual
Studio Code.

- **Terminal**: Ghostty.

- **Virtualisation**: Qemu, KVM, virt-manager.

- **Hardware**: Pilots and tools for AMD/Intel/Nvidia GPUs. Your GPU should be
detected during the installation and enabled accordingly.

- **Gaming**: Steam, Steam auto-start (BigPicture mode), ProtonGE for Steam, Heroic
Launcher, RetroArch.

- **Specialized Apps**:
  - OBS Studio, Audacity, DaVinci Resolve (Studio), Darktable.
  - Nmap/Zenmap, Wireshark, Remmina, Cloudflared.
  - Bitcoin: Electrum/Sparrow wallets, Coingecko, Bisq2, mempool web app.
  - Engineering: FreeCAD, LibreCAD, Open CAD Studio (CAD 2D/3D), KiCad (EDA),
    OrcaSlicer (3D printing), Blender, f3d (3D creation).

### Adding more Applications

Do you want a package not already included in one of the already pre-configured
[modules](https://github.com/CuriosLabs/CuriOS/tree/master/modules)? Add any
package found at [NixOS search packages](https://search.nixos.org/packages?sort=relevance&type=packages)?

For example, you want to install [Blender](https://www.blender.org/):

1. Launch `curios-manager` (shortcut: Super+Return)
2. Go the `Applications` menu, then `Find/Add a NixOS package` menu.
3. Type an application name, the script will search for the most pertinent results.
4. Choose an application from the result list:
   ![curios-manager add package screenshot 5](https://github.com/CuriosLabs/CuriOS/blob/master/img/curios-manager_addpackage5.png?raw=true "CuriOS manager add package 5")
5. `curios-manager` will now download and install the package.
6. Enjoy!

### Flatpak / Desktop Apps Installation

You can also install Linux applications as Flatpaks. [Flathub](https://flathub.org/)
and COSMIC repositories come pre-installed by default. Use the "COSMIC store"
app as seen below:
![COSMIC Store screenshot](https://github.com/CuriosLabs/CuriOS/blob/master/img/Store.png?raw=true "COSMIC Store")

## Backup your computer

With `curios-manager` you can also backup your computer on a local USB drive or
a cloud-based service. See our [Backup your Computer guide](backups.md).

## System management

From `curios-manager` system menu:
![curios-manager system menu](https://github.com/CuriosLabs/CuriOS/blob/master/img/curios-manager_system_menu2.png?raw=true "curios-manager system menu")

You can shutdown/reboot/lock your computer, manage running processes on your CPU
and GPU (with `btop` and `nvtop`), and see all current network connections (with
`snitch`). You can also check your disk usage, and update your firmware (UEFI
BIOS and more).
![curios-manager system disk](https://github.com/CuriosLabs/CuriOS/blob/master/img/curios-manager_systems_disk2.png?raw=true "curios-manager system disk")

## System Upgrade

Curi*OS* should upgrade and update itself every night or a few minutes after your
first boot of the day; see `systemctl list-timers`.

To manually start the system upgrade, launch `curios-manager` from a terminal (shortcut:
Super+Return) and choose the `👆Upgrade` option from the main menu.

## Themes

Curi*OS* comes with multiple desktop themes that you can easily switch using
`curios-manager` (shortcut: Super+Return):

1. Launch `curios-manager`
2. Go to the `Themes` menu
3. Browse the list of available themes using the arrow keys
4. Press Enter to apply the selected theme

Themes change the appearance of:

- The COSMIC desktop environment
- Alacritty and Ghostty terminals
- LazyVim (Neovim), Herdr, Brave browser, and Zed editor
- Wallpapers are also changed by the selected theme

![CuriOS themes](https://github.com/CuriosLabs/CuriOS/blob/release/26.05.10/img/Desktop-themes.png?raw=true "CuriOS themes")

Available themes:

- Catppuccin Macchiato
- COSMIC Dark
- Everforest Medium
- Gruvbox Dark
- Hackers
- Kanagawa
- Nord Dark
- Nord Light
- One Dark (default)
- Tokyo Night

Themes are provided by [curios-themes](https://github.com/CuriosLabs/curios-themes).
To learn how to create a custom theme, see
[curios-dotfiles](https://github.com/CuriosLabs/curios-dotfiles).

Themes can also include "dotfiles" that will be copied to your home directory
during a `curios-dotfiles --upgrade`. See the
[curios-dotfiles repository](https://github.com/CuriosLabs/curios-dotfiles) or
run `curios-dotfiles --help` and `curios-dotfiles --info` for more information.

## Command-line Tools

For advanced usage, Curi*OS* provides two CLI tools alongside the TUI
`curios-manager`. These are useful for scripting or when you prefer the
command line.

### `curios-update`

System-level operations: update/upgrade the system, search and install
packages, manage CuriOS modules, and query NixOS options.

```bash
# Update all packages and Nix flakes, then garbage-collect
sudo curios-update --update

# Upgrade to the latest CuriOS version
sudo curios-update --upgrade

# Search for a CuriOS module by name
curios-update --search-modules firefox

# Query any NixOS or CuriOS option
curios-update --nixos-option curios.system.timeZone

# Show all CuriOS module settings (JSON)
curios-update --show-modules

# Enable/disable a CuriOS module
sudo curios-update --update-module curios.desktop.browser.firefox.enable true

# Search for a NixOS package
curios-update --search-pkgs blender

# Install a NixOS package
sudo curios-update --add-pkg blender

# Export current module configuration to /etc/nixos/modules.json
sudo curios-update --export
```

Run `curios-update --help` for the full list of options.

### `curios-dotfiles`

Manage desktop themes, wallpapers, and dotfiles:

```bash
# List available themes
curios-dotfiles --list

# Apply a theme to your home directory
curios-dotfiles --themes "One Dark" /home/user

# Set the COSMIC keyboard layout
curios-dotfiles --lang fr /home/user

# Upgrade dotfiles and themes from Git
curios-dotfiles --upgrade /home/user

# Install as skeleton for new users
sudo curios-dotfiles /etc/skel/

# Show information about the dotfiles repository
curios-dotfiles --info
```

Themes and dotfiles are sourced from a Git repository. The default source is
`https://github.com/CuriosLabs/curios-themes`. Advanced users can use their own
themes and dotfiles from any valid Git URL by changing the options
`curios.core.dotfiles.url` and `curios.core.dotfiles.branch`.

Run `curios-dotfiles --help` for the full list of options.

## NixOS Management

Curi*OS* is built on top of NixOS, a Linux distribution based on the Nix
package manager and build system. It supports reproducible and declarative
system-wide configuration management, as well as atomic upgrades and rollbacks,
although it can additionally support imperative package and user management.
In NixOS, all components of the distribution—including the kernel, installed
packages, and system configuration files—are built by Nix from pure functions
called Nix expressions.
See the [NixOS manual](https://nixos.org/manual/nixos/stable/) to learn more.
NixOS generations older than 15 days are automatically garbage collected.

Most advanced users can manually edit the Curi*OS* system settings file
`/etc/nixos/settings.nix` from the `Settings (manual edit)` menu in order to add
custom Nix configuration changes. It launches the system `$EDITOR`, which is `nano`
by default.
![curios-manager settings screenshot](https://github.com/CuriosLabs/CuriOS/blob/master/img/curios-manager_settingsedit3.png?raw=true "CuriOS manager settings")

Save the change on exit with `Ctrl+X`. `curios-manager` will then perform a
whole system update.

## Default Terminal

By default, CuriOS uses [Alacritty](https://alacritty.org/) as the terminal emulator.
The COSMIC Terminal (`cosmic-term`) is also available.

Another option is [Ghostty](https://ghostty.org/). To install it, run:

```bash
sudo curios-update --update-module curios.desktop.devops.terminal.ghostty.enable true && \
sudo curios-update --update
```

To set your preferred terminal emulator, create `~/.config/xdg-terminals.list`:

```bash
touch ~/.config/xdg-terminals.list
```

For example, to set Ghostty as the default:

```bash
echo "com.mitchellh.ghostty.desktop" >> ~/.config/xdg-terminals.list
```

You can then use the `xdg-terminal-exec` command to launch programs in your
preferred terminal. For example:

```bash
xdg-terminal-exec btop
```

CuriOS desktop icons and COSMIC keyboard shortcuts use `xdg-terminal-exec` to
launch terminal applications.

The default terminal priority is defined in `/etc/xdg/cosmic-xdg-terminals.list`:

```
Alacritty.desktop
com.mitchellh.ghostty.desktop
com.system76.CosmicTerm.desktop
```

---
**Next**: [Backup your computer](backups.md).

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md).
