# Gaming Applications

Curi*OS* can install a gaming suite for Steam, Windows game compatibility,
emulation, and hardware extras. **No gaming application is installed by
default** — enable only what you need.

## Enable gaming apps

Install gaming applications via the **Curi*OS* Manager**:

1. Open `curios-manager` (Shortcut: `Super+Return`).
2. Go to the `Applications` menu, then `Install/uninstall CuriOS Apps` menu.
3. Search for `(curios.desktop) gaming` or a specific app name.
4. Toggle the application options that you need (Space bar).
5. Press Enter to Save and `curios-manager` will handle the installation.

From a terminal, you can do the same with `curios-update`. For example, to
install Steam:

```bash
sudo curios-update --update-module curios.desktop.gaming.enable true && \
sudo curios-update --update-module curios.desktop.gaming.steam.enable true && \
sudo curios-update --update
```

Enabling the gaming module allows unfree packages, which Steam requires. It
also loads the `ntsync` kernel module, used by Proton-GE to improve
compatibility with Windows games.

These tools are installed when `(curios.desktop) gaming` is enabled:

- **GameMode** (`gamemoderun`): asks the system for a gaming performance profile
  while a game is running. See
  [GameMode](https://github.com/FeralInteractive/gamemode).
- **Input Remapper**: remap keyboard, mouse, and gamepad controls.
- **steam-run**: run a program inside Steam's runtime. Useful for games and
  tools that expect a standard Linux filesystem layout.

## Steam and Proton-GE

Enable Steam with `(curios.desktop.gaming) steam`
(`curios.desktop.gaming.steam.enable`).

Steam on Curi*OS* comes with **Proton-GE** (GloriousEggroll). Proton is a
compatibility layer that runs Windows games on Linux. Proton-GE is a community
build with extra fixes on top of Valve's Proton. It is not forced on every
game: try it when the default Proton build does not run a Windows-only game
well.

To try Proton-GE for one game:

1. In Steam, right-click the game and choose **Properties**.
2. Open the **Compatibility** tab.
3. Enable **Force the use of a specific Steam Play compatibility tool**.
4. Select **Proton-GE** (it may appear as **GE-Proton**).

Native Linux games do not need a compatibility tool.

### Launch options for Windows-only games

For a Windows-only game, start it through GameMode. In the same **Properties**
window, on the **General** tab, set **Launch Options** to:

```text
gamemoderun %command%
```

`%command%` is a Steam placeholder. Steam replaces it with the game's own
command, so GameMode starts first and then launches the game.

Launch options differ from one game to another. Visit
[ProtonDB](https://www.protondb.com/), search for the game, and copy the launch
option reported for a working setup into **Launch Options**. To keep GameMode,
put `gamemoderun` in front of that option. For example, if ProtonDB suggests
`PROTON_ENABLE_NVAPI=1 %command%`, use:

```text
gamemoderun PROTON_ENABLE_NVAPI=1 %command%
```

## Steam Big Picture

To launch Steam in Big Picture mode when you log in to the desktop, also enable
`curios.desktop.gaming.steam.bigpicture.autoStart`.

## Other applications

- **Heroic Games Launcher**: install and play games from the Epic Games Store,
  GOG, and Amazon (`curios.desktop.gaming.heroic.enable`).
- **RetroArch**: libretro frontend, with cores and joystick autoconfiguration
  (`curios.desktop.gaming.retroarchFree.enable`).
- **OpenRGB**: open-source RGB lighting control
  (`curios.desktop.gaming.openrgb.enable`).

---
**Next**: [Virtualisation](virtualisation.md).

**Previous**: [Engineering applications](engineering.md)

**Back**: [index](index.md).
