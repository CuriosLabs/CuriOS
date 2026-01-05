# Curi*OS* management

Curi*OS* come with a TUI `curios-manager` (shortcut: Super+Return).
![curios-manager screenshot](https://github.com/CuriosLabs/CuriOS/blob/master/img/CuriOS-manager.png?raw=true "CuriOS manager")

With it, you can update/upgrade the whole system, update your hardware firmware
, check your disk usage, launch the process manager (btop), and much more...

Use arrow keys to move the cursor up and down, Enter to select, Esc to abort.

Most importantly you can manually edit the Curi*OS* system settings file
`/etc/nixos/settings.nix` from the menu `System > Settings`.
![curios-manager settings screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settings.png?raw=true "CuriOS manager settings")

For example, you want to game and install Steam, Heroic launcher, Discord and
more?

Set: `gaming.enable` to `true;`, as seen below:
![curios-manager settings editor screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/CuriOS-manager_settingsedit.png?raw=true "CuriOS manager settings editor")
Save the change with `Ctrl+S` and exit with `Ctrl+X`, `curios-manager` will
then made a whole system update.

You want a package not in one of the already pre-configured [modules](https://github.com/CuriosLabs/CuriOS/tree/master/modules)
? Find more packages or options configuration at [NixOS packages](https://search.nixos.org/packages?channel=25.11&size=50&sort=relevance&type=packages)
and add it to `/etc/nixos/settings.nix`.

## Available applications

TBD

## Flatpak / desktop apps installation

You can also install Linux applications as flatpak. [Flathub](https://flathub.org/)
and COSMIC repositories come pre-installed by default. Use the "COSMIC store"
app as seen below:
![COSMIC Store screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Store.png?raw=true "COSMIC Store")

## System upgrade

When a new version of Curi*OS* is available, you will see a pop-up appear on
your desktop:
![CuriOS updater screenshot](https://github.com/CuriosLabs/CuriOS/blob/testing/img/Updater2.png?raw=true "CuriOS updater")

To start the system upgrade, launch `curios-manager` from a terminal (shortcut:
Super+Return) and choose the `👆Upgrade` option.

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

**Next**: .

**Previous**: [First Steps](first-steps.md).

**Back**: [index](index.md).
