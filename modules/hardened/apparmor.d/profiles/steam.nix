# Steam AppArmor profiles.
# Profiles: steam, steam-launch, steam-gameoverlayui, steam-fossilize, steam-game-proton, steam-game-native

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.policies = {
      "steam" = {
        state = cfg.desktop.gaming.steam.mode;
        profile = let
          modeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(complain, attach_disconnected, mediate_deleted)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
          webModeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(attach_disconnected, mediate_deleted, complain)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{lib_dirs} = ${pkgs.steam.fhsenv}
          @{config_dirs} = @{HOME}/.local/share/Steam

          profile steam @{config_dirs}/steam.sh ${modeFlag} {
            include <abstractions/curios/fhsenv-bwrap>
            include <abstractions/curios/graphics>
            include <abstractions/curios/wayland>
            include <abstractions/audio>
            include <abstractions/curios/dconf>
            include <abstractions/curios/nss>
            include <abstractions/curios/wine>
            include <abstractions/curios/secrets-deny>
            include <abstractions/curios/secrets-deny-browsers>

            # NixOS shared libraries (Steam is 32-bit + 64-bit multiarch)
            /nix/store/*/lib{,32,64}/**.so*                                    mr,

            # Steam FHS-env bwrap chain (app-specific, not exposed via pkgs)
            /nix/store/*-steam-*-init                                          rix,
            /nix/store/*-steam-wrapped                                         rix,

            # Steam Valve runtime entry points (self-managed, outside nix store)
            @{config_dirs}/steam.sh                                            mrix,
            @{config_dirs}/ubuntu12_32/steam*                                  mrix,
            @{config_dirs}/ubuntu12_{32,64}/{gldriverquery,vulkandriverquery}  rix,
            # rPx blocked by bwrap no_new_privs; standalone profile still
            # attaches if gameoverlayui is exec'd outside the steam NNP tree
            @{config_dirs}/ubuntu12_{32,64}/gameoverlayui                      mrix,
            @{config_dirs}/ubuntu12_{32,64}/reaper                             rix,
            @{config_dirs}/ubuntu12_{32,64}/fossilize_replay                   mrix,
            @{config_dirs}/steamrt{32,64}/fossilize_replay                     mrix,
            @{config_dirs}/bin/hardwareupdater/hardwareupdater.x86_64          rix,

            # steamwebhelper wrap stays here; the CEF binary enters steam//web
            @{config_dirs}/ubuntu12_64/steamwebhelper.sh                       rix,
            @{config_dirs}/ubuntu12_64/steamwebhelper_sniper_wrap.sh           rix,
            # cix/Cx → web is blocked by bwrap no_new_privs; inherit instead
            @{config_dirs}/ubuntu12_64/steamwebhelper                          mrix,

            # Scout runtime helpers
            @{config_dirs}/ubuntu12_32/steam-runtime/{run,setup}.sh            rix,
            @{config_dirs}/ubuntu12_32/steam-runtime/{amd64,i386}/usr/bin/lsof rix,
            @{config_dirs}/ubuntu12_32/steam-runtime/{amd64,i386}/usr/bin/steam-runtime-* rix,
            @{config_dirs}/ubuntu12_32/steam-runtime/**/srt-bwrap              rix,
            @{config_dirs}/ubuntu12_32/steam-runtime/**/srt-logger             rix,
            @{config_dirs}/ubuntu12_32/steam-runtime/**/*srt-launcher-service  rix,

            # pressure-vessel / steamrt (webhelper + Proton / SLR)
            @{config_dirs}/steamrt64/**/_v2-entry-point                        rix,
            @{config_dirs}/steamrt64/**/run                                    rix,
            @{config_dirs}/steamrt64/**/pressure-vessel/bin/pressure-vessel-*  rix,
            @{config_dirs}/steamrt64/**/pressure-vessel/libexec/steam-runtime-tools-@{int}/* rix,
            @{config_dirs}/steamapps/common/SteamLinuxRuntime*/_v2-entry-point rix,
            @{config_dirs}/steamapps/common/SteamLinuxRuntime*/run             rix,
            @{config_dirs}/steamapps/common/SteamLinuxRuntime*/pressure-vessel/bin/pressure-vessel-* rix,
            @{config_dirs}/steamapps/common/SteamLinuxRuntime*/pressure-vessel/libexec/steam-runtime-tools-@{int}/* rix,
            /usr/lib/pressure-vessel/from-host/libexec/steam-runtime-tools-@{int}/* rix,
            /usr/bin/steam-runtime-launcher-interface-@{int}                   rix,

            # Proton GE (nixpkgs extraCompatPackages) + Valve Proton in steamapps.
            # rPx -> steam-game-proton blocked by bwrap NNP; inherit instead.
            /nix/store/*-proton-ge-bin-*-steamcompattool/**                    mrix,
            /nix/store/*-source/proton                                         mrix,
            /nix/store/*-source/files/bin/{wine,wineserver,msidb,xrandr}       mrix,
            /nix/store/*-source/files/lib/wine/**                              mrix,
            /nix/store/*-source/files/lib/**.so*                               mr,
            /nix/store/*-source/protonfixes/files/bin/*                        mrix,
            # Native + Proton + SLR binaries in all Steam libraries.
            # rPx -> steam-game-native blocked by bwrap NNP; inherit instead.
            @{config_dirs}/steamapps/common/**                                 mrix,
            owner @{HOME}/**/steamapps/common/**                               mrix,
            /run/media/**/steamapps/common/**                                  mrix,
            /usr/bin/python3                                                   rix,
            /usr/bin/python3.*                                                 rix,
            /nix/store/*-python3-*/bin/python3*                                rix,

            # Network (client, downloads, multiplayer, In-Home Streaming)
            network inet dgram,
            network inet6 dgram,
            network inet stream,
            network inet6 stream,
            network netlink raw,

            # Unprivileged user namespaces (pressure-vessel / Proton)
            userns,
            capability sys_admin,
            capability sys_chroot,
            capability sys_ptrace,
            capability sys_nice,
            capability mknod,
            capability dac_override,
            capability dac_read_search,

            # Shell and utilities (store + FHS view inside bwrap).
            # FHSEnv ships its own bash-interactive hash, not pkgs.bashInteractive.
            /nix/store/*-bash-interactive-*/bin/{sh,bash}                      rix,
            /usr/bin/env                                                       rix,
            /bin/sh                                                            rix,
            /usr/bin/bash                                                      rix,
            ${pkgs.coreutils-full}/bin/*                                       rix,
            ${pkgs.coreutils}/bin/*                                            rix,
            ${pkgs.gnugrep}/bin/grep                                           rix,
            ${pkgs.gnused}/bin/sed                                             rix,
            ${pkgs.gawk}/bin/{awk,gawk}                                        rix,
            ${pkgs.gzip}/bin/gzip                                              rix,
            ${pkgs.which}/bin/which                                            rix,
            ${pkgs.getopt}/bin/getopt                                          rix,
            ${pkgs.xdg-user-dirs}/bin/xdg-user-dir                             rix,
            /usr/bin/{awk,cat,dash,getopt,gzip,ldd,ln,localedef,mkdir,readlink,rm,uname,which,xdg-user-dir} rix,

            # System tools (hardware detection, dependency checks)
            ${pkgs.lsb-release}/bin/lsb_release                                rix,
            ${pkgs.pciutils}/bin/lspci                                         rix,
            ${pkgs.xz}/bin/xz                                                  rix,
            ${pkgs.glibc.bin}/bin/ldconfig                                     rix,
            ${pkgs.glibc.bin}/bin/localedef                                    rix,
            /nix/store/*-glibc-*-bin/bin/{ldconfig,localedef}                  rix,
            /nix/store/*-glibc-multi-*-bin/bin/ldd                             rix,
            /nix/store/*-ldconfig/bin/ldconfig                                 rix,
            /nix/store/*-glibc-*/lib/ld-linux{,-x86-64}.so*                    rix,
            /sbin/ldconfig                                                     rix,
            /usr/sbin/ldconfig                                                 rix,
            ${pkgs.wireplumber}/bin/wpctl                                      rix,
            ${pkgs.pulseaudio}/bin/pactl                                       rix,
            /nix/store/*-pulseaudio-*/.bin-unwrapped/pactl                     rix,
            /run/current-system/sw/bin/{wpctl,pactl}                           rix,

            # Process inspection (game detection, overlay, wineserver).
            # Restrict to the steam tree so a game cannot dump ssh-agent/browsers.
            ptrace (read,trace) peer=steam,

            # Signal child processes (steamwebhelper, game sandboxes)
            signal send set=(kill term) peer=steam//web,
            signal send set=(kill term) peer=steam-gameoverlayui,
            signal send set=(kill term) peer=steam-fossilize,
            signal send set=(kill term) peer=steam-game-proton,
            signal send set=(kill term) peer=steam-game-native,

            # Steam home (~/.steam/ symlink or directory)
            owner @{HOME}/.steam/                                              rwk,
            owner @{HOME}/.steam/**                                            rwkm,
            owner @{HOME}/.steampath                                           rw,
            owner @{HOME}/.steampid                                            rw,

            # Steam data (~/.local/share/Steam/). 'l' needed for
            # pressure-vessel hardlinks into var/tmp-*.
            owner @{config_dirs}/                                              rwk,
            owner @{config_dirs}/**                                            rwlkm,

            # Steam libraries only (not the whole visible home).
            owner @{HOME}/Games/                                               rwk,
            owner @{HOME}/Games/**                                             rwlkm,
            owner @{HOME}/games/                                               rwk,
            owner @{HOME}/games/**                                             rwlkm,
            owner @{HOME}/**/steamapps/                                        rwk,
            owner @{HOME}/**/steamapps/**                                      rwlkm,
            /run/media/                                                        r,
            /run/media/**/steamapps/                                           r,
            /run/media/**/steamapps/**                                         rwlkm,

            # Crash dumps (bind-mounted via bwrap --bind-try /tmp/dumps)
            owner /tmp/dumps/                                                  rwk,
            owner /tmp/dumps/**                                                rwkm,

            # Steam IPC shared memory
            owner /dev/shm/ValveIPCSHM_@{uid}                                  rw,
            owner /dev/shm/u@{uid}-Shm_*                                       rw,
            owner /dev/shm/u@{uid}-ValveIPCSharedObj-Steam                     rwk,

            # Game controllers, HID devices, VR
            /dev/input/                                                        r,
            /dev/input/*                                                       rw,
            /dev/uinput                                                        rw,
            /dev/hidraw*                                                       rw,

            # Controller/input sysfs
            @{sys}/class/hidraw/                                               r,
            @{sys}/class/input/                                                r,
            @{sys}/devices/**/input*/**                                        r,
            @{sys}/devices/**/report_descriptor                                r,

            # Distro identification (Steam runtime detection)
            /etc/lsb-release                                                   r,
            /etc/timezone                                                      r,

            # Directory listing (Steam walks parents to find libraries)
            /                                                                  r,
            /etc/                                                              r,
            /home/                                                             r,
            /usr/                                                              r,
            /var/                                                              r,
            /var/lib/                                                          r,
            /var/tmp/                                                          r,
            owner @{HOME}/                                                     r,
            owner @{HOME}/.local/                                              r,
            owner @{HOME}/.local/share/                                        r,
            owner @{HOME}/.config/                                             r,
            owner @{HOME}/.config/autostart/                                   r,
            owner @{HOME}/.config/user-dirs.dirs                               r,
            owner @{HOME}/.config/unity3d/                                     rwk,
            owner @{HOME}/.config/unity3d/**                                   rwlkm,
            owner @{HOME}/.mono/                                               rwk,
            owner @{HOME}/.mono/**                                             rwlkm,
            /run/                                                              r,
            owner @{run}/user/@{uid}/                                          r,
            /nix/                                                              r,
            /nix/store/                                                        r,

            # Process and CPU monitoring (game detection)
            @{PROC}/                                                           r,
            @{PROC}/1/cgroup                                                   r,
            @{PROC}/locks                                                      r,
            @{PROC}/self/exe                                                   rix,
            @{PROC}/sys/user/max_user_namespaces                               r,
            owner @{PROC}/@{pid}/cmdline                                       r,
            owner @{PROC}/@{pid}/environ                                       r,
            owner @{PROC}/@{pid}/fd/                                           r,
            owner @{PROC}/@{pid}/fdinfo/@{int}                                 r,
            owner @{PROC}/@{pid}/mounts                                        r,
            owner @{PROC}/@{pid}/mountinfo                                     r,
            owner @{PROC}/@{pid}/stat                                          r,
            owner @{PROC}/@{pid}/statm                                         r,
            owner @{PROC}/@{pid}/status                                        r,
            owner @{PROC}/@{pid}/mem                                           r,
            owner @{PROC}/@{pid}/clear_refs                                    w,
            owner @{PROC}/@{pid}/oom_score_adj                                 w,
            owner @{PROC}/@{pid}/task/                                         r,
            owner @{PROC}/@{pid}/task/@{tid}/comm                              rw,
            owner @{PROC}/@{pid}/task/@{tid}/children                          r,
            @{PROC}/@{pid}/stat                                                r,
            @{PROC}/@{pid}/statm                                               r,
            @{PROC}/@{pid}/comm                                                rk,
            @{PROC}/@{pid}/fdinfo/@{int}                                       r,
            @{PROC}/@{pid}/task/@{tid}/status                                  r,
            @{PROC}/@{pid}/net/*                                               r,
            @{PROC}/version                                                    r,
            @{PROC}/sys/kernel/yama/ptrace_scope                               r,
            @{PROC}/sys/kernel/sched_autogroup_enabled                         r,

            @{sys}/                                                            r,
            @{sys}/kernel/                                                     r,
            @{sys}/devices/virtual/dmi/id/                                     r,
            @{sys}/devices/virtual/dmi/id/*                                    rk,
            @{sys}/devices/system/node/                                        r,
            @{sys}/devices/system/node/**                                      r,
            @{sys}/devices/system/clocksource/**                               r,
            @{sys}/devices/virtual/net/*/carrier                               r,
            @{PROC}/sys/net/core/bpf_jit_enable                                r,
            @{PROC}/sys/fs/file-max                                            r,
            @{PROC}/pressure/io                                                r,
            @{PROC}/uptime                                                     r,
            owner @{PROC}/@{pid}/autogroup                                     rw,
            owner @{PROC}/@{pid}/pagemap                                        r,
            @{PROC}/@{pid}/task/@{tid}/stat                                    r,
            /dev/                                                              r,
            /dev/ntsync                                                        r,
            /dev/ttyS*                                                         r,
            /dev/bus/usb/                                                      r,
            /dev/bus/usb/**                                                    r,
            @{sys}/power/suspend_stats/success                                 rk,
            @{sys}/devices/virtual/net/                                        r,
            @{sys}/devices/virtual/net/*/                                      r,
            /dev/disk/by-id/                                                   r,

            # srt-logger FIFOs
            owner @{run}/user/@{uid}/srt-fifo.*/                               rwk,
            owner @{run}/user/@{uid}/srt-fifo.*/**                             rwk,

            # pressure-vessel host view + ld.so cache
            /run/host/                                                         r,
            /run/host/**                                                       r,
            /run/pressure-vessel/                                              r,
            /run/pressure-vessel/**                                            r,
            /var/pressure-vessel/                                              rwk,
            /var/pressure-vessel/**                                            rwk,
            /var/cache/ldconfig/                                               rwk,
            /var/cache/ldconfig/**                                             rwk,
            /var/cache/fontconfig/                                             rwlk,
            /var/cache/fontconfig/**                                           rwlk,

            # pressure-vessel transient bind files + locale staging
            owner /bindfile*                                                   rw,
            owner /tmp/pressure-vessel-locales-*/                              rwk,
            owner /tmp/pressure-vessel-locales-*/**                            rwlk,
            # PyInstaller extract (hardwareupdater)
            owner /tmp/_MEI*/                                                  rwk,
            owner /tmp/_MEI*/**                                                rwkm,

            # Font file locks (Steam probes with flock)
            /nix/store/**                                                      rk,

            # Desktop integration
            owner @{HOME}/.local/share/applications/*.desktop                  rw,
            owner @{HOME}/.local/share/icons/hicolor/**/apps/steam*            rw,

            # Vulkan implicit layers (Steam overlay, Fossilize shader cache)
            owner @{HOME}/.local/share/vulkan/implicit_layer.d/steam*.json     rwk,

            # URL handling (Steam store links, community)
            ${pkgs.xdg-utils}/bin/xdg-open                                     rix,
            /run/current-system/sw/bin/xdg-open                                rix,
            ${pkgs.brave}/bin/brave                                            rPx -> brave-wrapper,

            # Flatpak exports (xdg-open resolving links to installed Flatpak apps)
            /var/lib/flatpak/exports/share/icons/                              r,
            /var/lib/flatpak/exports/share/icons/**                            r,
            /var/lib/flatpak/exports/share/applications/                       r,
            /var/lib/flatpak/exports/share/applications/**                     r,

            # GTK theme (Steam uses GTK3/4 for file dialogs, settings UI)
            owner @{HOME}/.config/gtk-3.0/**                                   r,
            owner @{HOME}/.config/gtk-4.0/**                                   r,

            # Silencers (secrets-deny covers ssh/gnupg/wallets/.env)

            # Steam web helper (CEF embedded browser — sandboxed)
            profile web ${webModeFlag} {
              include <abstractions/base>
              include <abstractions/nameservice>
              include <abstractions/audio>
              include <abstractions/consoles>
              include <abstractions/fonts>
              include <abstractions/dconf>
              include <abstractions/ssl_certs>
              include <abstractions/curios/dconf>
              include <abstractions/curios/devices>
              include <abstractions/curios/gconv>
              include <abstractions/curios/graphics>
              include <abstractions/curios/wayland>

              # Signal handling (receive from parent steam process)
              signal receive set=(cont kill term) peer=steam,

              # NixOS shared libraries
              /nix/store/*/lib{,32,64}/**.so*                                  mr,
              /nix/store/**                                                    r,

              # FHS env rootfs (CEF libs and steamwebhelper binary)
              @{lib_dirs}/                                                     r,
              @{lib_dirs}/**                                                   mr,

              @{config_dirs}/ubuntu12_64/steamwebhelper                        mrix,
              @{config_dirs}/ubuntu12_64/steamwebhelper*                       rix,
              @{config_dirs}/ubuntu12_32/steam-runtime/**/srt-logger           rix,
              @{config_dirs}/steamrt64/**/_v2-entry-point                      rix,
              @{config_dirs}/steamrt64/**/run                                  rix,
              @{config_dirs}/steamrt64/**/pressure-vessel/bin/pressure-vessel-*  rix,
              @{config_dirs}/steamrt64/**/pressure-vessel/libexec/steam-runtime-tools-@{int}/* rix,
              /usr/lib/pressure-vessel/from-host/libexec/steam-runtime-tools-@{int}/* rix,

              # Chromium sandbox (CEF uses the same sandbox as Chromium)
              userns,
              capability sys_admin,
              capability sys_chroot,
              capability sys_ptrace,
              capability mknod,
              capability dac_override,
              capability dac_read_search,

              # Network (store, library, community, chat)
              network inet dgram,
              network inet6 dgram,
              network inet stream,
              network inet6 stream,
              network netlink raw,

              # Shell (wrapper scripts)
              ${pkgs.bashInteractive}/bin/sh                                   rix,
              ${pkgs.bashInteractive}/bin/bash                                 rix,
              ${pkgs.coreutils-full}/bin/*                                     rix,
              ${pkgs.coreutils}/bin/*                                          rix,

              # Steam data access (read config, write cache/logs)
              owner @{config_dirs}/                                            r,
              owner @{config_dirs}/**                                          rwlkm,
              owner @{config_dirs}/config/**                                   rwk,
              owner @{config_dirs}/logs/**                                     rwk,
              owner @{config_dirs}/public/**                                   r,
              owner @{config_dirs}/appcache/**                                 r,

              owner @{run}/user/@{uid}/srt-fifo.*/                             rwk,
              owner @{run}/user/@{uid}/srt-fifo.*/**                           rwk,
              /run/host/                                                       r,
              /run/host/**                                                     r,
              /run/pressure-vessel/                                            r,
              /run/pressure-vessel/**                                          r,
              /var/pressure-vessel/                                            rwk,
              /var/pressure-vessel/**                                          rwk,

              # Steam IPC shared memory
              owner /dev/shm/ValveIPCSHM_@{uid}                                rw,
              owner /dev/shm/u@{uid}-Shm_*                                     rw,
              owner /dev/shm/u@{uid}-ValveIPCSharedObj-Steam                   rwk,

              # Temp (CEF shared memory, downloads)
              /tmp/                                                            r,
              owner /tmp/steam_chrome_shmem_*                                  rw,
              owner /tmp/.com.valvesoftware.Steam.*/**                         rw,
              owner /tmp/#@{int}                                               rw,

              # Process info (parent/child monitoring)
              owner @{PROC}/@{pid}/cmdline                                     r,
              owner @{PROC}/@{pid}/environ                                     r,
              owner @{PROC}/@{pid}/fd/                                         r,
              owner @{PROC}/@{pid}/fdinfo/@{int}                               r,
              owner @{PROC}/@{pid}/stat                                        r,
              owner @{PROC}/@{pid}/statm                                       r,
              owner @{PROC}/@{pid}/status                                      r,
              owner @{PROC}/@{pid}/clear_refs                                  w,
              owner @{PROC}/@{pid}/oom_score_adj                               w,
              @{PROC}/sys/user/max_user_namespaces                             r,
              @{PROC}/@{pid}/stat                                              r,
              @{PROC}/@{pid}/task/@{tid}/comm                                  r,
              @{PROC}/@{pid}/task/@{tid}/status                                r,
              @{PROC}/version                                                  r,
              @{PROC}/sys/kernel/yama/ptrace_scope                             r,
              @{PROC}/sys/fs/inotify/max_user_watches                          r,

              # D-Bus
              owner @{run}/user/@{uid}/bus                                     rw,

              # PipeWire audio
              owner @{run}/user/*/pipewire-*                                   rw,

              include if exists <local/steam_web>
            }

            include if exists <local/steam>
          }
        '';
      };

      "steam-launch" = {
        state = cfg.desktop.gaming.steam.mode;
        profile = let
          modeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(complain, attach_disconnected, mediate_deleted)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{lib_dirs} = ${pkgs.steam.fhsenv}
          @{share_dirs} = @{HOME}/.local/share/Steam @{HOME}/.steam/steam @{HOME}/.steam/root
          @{libsteam_dirs} = @{share_dirs}/ubuntu12_{32,64} @{share_dirs}/linux{32,64}
          @{exec_path} = ${pkgs.steam}/bin/steam ${pkgs.steam-unwrapped}/bin/steam

          # NixOS entry is the FHSEnv wrapper; AppArmor resolves the symlink
          # to *-steam-*-bwrap. Inside the namespace /usr/bin/steam is
          # steam-unwrapped (bin_steam.sh), which then execs steam.sh.
          profile steam-launch @{exec_path} ${modeFlag} {
            include <abstractions/curios/fhsenv-bwrap>

            network unix stream,

            ${pkgs.steam}/bin/steam                                            rix,
            /nix/store/*-steam-*-bwrap                                         rix,
            /nix/store/*-steam-*-init                                          rix,
            /nix/store/*-steam-wrapped                                         rix,
            /run/current-system/sw/bin/steam                                   rix,

            # Valve launcher (store path + FHS view inside bwrap)
            ${pkgs.steam-unwrapped}/bin/steam                                  rix,
            ${pkgs.steam-unwrapped}/lib/steam/bin_steam.sh                     rix,
            ${pkgs.steam-unwrapped}/lib/steam/**                               r,
            /usr/bin/steam                                                     rix,
            /usr/lib/steam/bin_steam.sh                                        rix,
            /usr/lib/steam/**                                                  r,

            # Steam client (self-managed under $HOME after first run)
            @{share_dirs}/steam.sh                                             rPx -> steam,

            # bin_steam.sh helpers (coreutils already in fhsenv-bwrap)
            ${pkgs.gnutar}/bin/tar                                             rix,
            ${pkgs.xz}/bin/xz                                                  rix,
            ${pkgs.zenity}/bin/zenity                                          rix,
            /usr/bin/{tar,xz,zenity,id,cmp,cp,mkdir,ln,chmod}                  rix,

            # Forward CLI to a running client
            @{libsteam_dirs}/steam-runtime/{amd64,i386}/usr/bin/steam-runtime-steam-remote rix,

            # srt-logger (sourced + exec from bin_steam.sh)
            @{libsteam_dirs}/steam-runtime/usr/libexec/steam-runtime-tools-@{int}/* r,
            @{libsteam_dirs}/steam-runtime/usr/libexec/steam-runtime-tools-@{int}/srt-logger rix,
            @{libsteam_dirs}/steam-runtime/{amd64,i386}/usr/bin/srt-logger     rix,

            # User-managed Steam binaries (not in the nix store)
            @{libsteam_dirs}/**                                                mr,
            @{HOME}/.steam/bin{,32,64}/**                                      mr,
            @{HOME}/.steam/sdk{32,64}/**                                       mr,

            # First-run bootstrap, logs, classic ~/Steam repair path
            owner @{share_dirs}/                                               rwk,
            owner @{share_dirs}/**                                             rwk,
            owner @{share_dirs}/bootstrap.tar.xz                               rw,
            owner @{share_dirs}/logs/                                          r,
            owner @{share_dirs}/logs/*                                         rwk,
            owner @{HOME}/Steam/                                               rwk,
            owner @{HOME}/Steam/**                                             rwk,

            # ~/.steam control directory (symlinks, pid, pipe, token)
            owner @{HOME}/.steam/                                              rwk,
            owner @{HOME}/.steam/**                                            rwk,
            owner @{HOME}/.steampath                                           rw,
            owner @{HOME}/.steampid                                            rw,

            owner @{HOME}/.config/user-dirs.dirs                               r,

            owner @{run}/user/@{uid}/srt-fifo.*/                               rw,
            owner @{run}/user/@{uid}/srt-fifo.*/fifo                           rw,

            owner @{PROC}/@{pid}/fd/@{int}                                     rw,

            /dev/tty                                                           rw,

            deny /opt/**                                                       r,

            include if exists <local/steam-launch>
          }
        '';
      };

      "steam-gameoverlayui" = {
        state = cfg.desktop.gaming.steam.mode;
        profile = let
          modeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(complain, attach_disconnected, mediate_deleted)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{config_dirs} = @{HOME}/.local/share/Steam
          @{overlay_dirs} = @{config_dirs}/ubuntu12_{32,64} @{config_dirs}/linux{32,64}

          profile steam-gameoverlayui @{overlay_dirs}/gameoverlayui ${modeFlag} {
            include <abstractions/base>
            include <abstractions/audio>
            include <abstractions/fonts>
            include <abstractions/curios/gconv>
            include <abstractions/curios/graphics>
            include <abstractions/curios/wayland>

            network inet stream,
            network inet6 stream,

            @{overlay_dirs}/gameoverlayui                                      mr,
            @{overlay_dirs}/**.so*                                             mr,
            @{config_dirs}/ubuntu12_32/steam-runtime/**.so*                    mr,
            /nix/store/*/lib{,32,64}/**.so*                                    mr,
            /nix/store/**                                                      r,

            @{overlay_dirs}/steamerrorreporter                                 rix,

            /                                                                  r,
            /home/                                                             r,
            /tmp/                                                              r,

            owner @{HOME}/                                                     r,
            owner @{HOME}/.steam/registry.vdf                                  rk,
            owner @{HOME}/.steam/steam.pipe                                    r,

            owner @{overlay_dirs}/fontconfig/                                  rwl,
            owner @{overlay_dirs}/fontconfig/**                                rwl,

            owner @{config_dirs}/                                              r,
            owner @{config_dirs}/**                                            r,
            owner @{config_dirs}/config/DialogConfigOverlay*.vdf               rw,
            owner @{config_dirs}/public/*                                      rk,
            owner @{config_dirs}/resource/**                                   rk,
            owner @{config_dirs}/userdata/@{int}/**                            rk,

            owner /dev/shm/ValveIPCSHM_@{uid}                                  rw,
            owner /dev/shm/u@{uid}-Shm_*                                       rw,
            owner /dev/shm/u@{uid}-ValveIPCSharedObj-Steam                     rwk,

            owner /tmp/gameoverlayui.log*                                      rw,
            owner /tmp/miles_image_*                                           mrw,
            owner /tmp/runtime-info.txt.*                                      rw,
            owner /tmp/steam_chrome_overlay_uid@{uid}_spid*                    rw,

            @{sys}/                                                            r,
            @{sys}/kernel/                                                     r,
            @{sys}/devices/                                                    r,
            @{sys}/devices/system/                                             r,
            @{sys}/devices/system/cpu/cpu@{int}/                               r,

            @{PROC}/version                                                    r,

            deny @{HOME}/.local/share/gvfs-metadata/*                          r,

            include if exists <local/steam-gameoverlayui>
          }
        '';
      };

      "steam-fossilize" = {
        state = cfg.desktop.gaming.steam.mode;
        profile = let
          modeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(complain, attach_disconnected, mediate_deleted)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{config_dirs} = @{HOME}/.local/share/Steam
          @{fossilize_dirs} = @{config_dirs}/ubuntu12_{32,64} @{config_dirs}/linux{32,64} @{config_dirs}/steamrt{32,64}

          profile steam-fossilize @{fossilize_dirs}/fossilize_replay ${modeFlag} {
            include <abstractions/base>
            include <abstractions/curios/gconv>
            include <abstractions/curios/graphics>
            include <abstractions/curios/wayland>

            signal receive peer=steam,

            @{fossilize_dirs}/fossilize_replay                                 mr,
            @{fossilize_dirs}/**                                               mr,
            /nix/store/*/lib{,32,64}/**.so*                                    mr,
            /nix/store/**                                                      r,

            owner @{HOME}/.steam/steam.pipe                                    r,

            owner @{config_dirs}/logs/container-runtime-info.txt.*             rw,
            owner @{config_dirs}/steamapps/shadercache/@{int}/fozpipelinesv@{int}/ rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/fozpipelinesv@{int}/** rw,
            owner @{config_dirs}/steamapps/shadercache/@{int}/fozmediav@{int}/  rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/fozmediav@{int}/** rw,
            owner @{config_dirs}/steamapps/shadercache/@{int}/mesa_shader_cache_sf/ rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/mesa_shader_cache_sf/** rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/nvidiav@{int}/GLCache/ rw,
            owner @{config_dirs}/steamapps/shadercache/@{int}/nvidiav@{int}/GLCache/** rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/DXVK_state_cache/ rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/DXVK_state_cache/** rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/radv_builtin_shaders/ rwk,
            owner @{config_dirs}/steamapps/shadercache/@{int}/radv_builtin_shaders/** rwk,

            owner /tmp/runtime-info.txt.*                                      rw,
            owner /dev/shm/fossilize-*                                         rw,

            @{sys}/devices/system/node/                                        r,
            @{sys}/devices/system/node/node@{int}/cpumap                       r,

            @{PROC}/@{pid}/statm                                               r,
            @{PROC}/pressure/io                                                r,
            owner @{PROC}/@{pid}/cmdline                                       r,
            owner @{PROC}/@{pid}/stat                                          r,
            owner @{PROC}/@{pid}/task/@{tid}/comm                              rw,

            deny network inet stream,
            deny @{HOME}/.local/share/gvfs-metadata/*                          r,

            include if exists <local/steam-fossilize>
          }
        '';
      };

      "steam-game-proton" = {
        state = cfg.desktop.gaming.steam.mode;
        profile = let
          modeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(complain, attach_disconnected, mediate_deleted)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{lib_dirs} = ${pkgs.steam.fhsenv}
          @{config_dirs} = @{HOME}/.local/share/Steam
          @{app_dirs} = @{config_dirs}/steamapps/common
          @{exec_path} = @{app_dirs}/SteamLinuxRuntime*/pressure-vessel/libexec/steam-runtime-tools-@{int}/srt-bwrap ${pkgs.proton-ge-bin.steamcompattool}/proton

          profile steam-game-proton @{exec_path} ${modeFlag} {
            include <abstractions/base>
            include <abstractions/curios/fhsenv-bwrap>
            include <abstractions/curios/graphics>
            include <abstractions/curios/wayland>
            include <abstractions/curios/wine>
            include <abstractions/curios/secrets-deny>
            include <abstractions/curios/secrets-deny-browsers>
            include <abstractions/audio>

            capability dac_override,
            capability dac_read_search,

            network inet dgram,
            network inet6 dgram,
            network inet stream,
            network inet6 stream,
            network unix stream,

            signal receive peer=steam,
            userns,

            @{exec_path}                                                       mr,
            /nix/store/*-proton-ge-bin-*-steamcompattool/**                    mrix,
            /nix/store/*-source/proton                                         mrix,
            /nix/store/*-source/files/bin/{wine,wineserver,msidb,xrandr}       mrix,
            /nix/store/*-source/files/lib/wine/**                              mrix,
            /nix/store/*-source/files/lib/**.so*                               mr,
            /nix/store/*/lib{,32,64}/**.so*                                    mr,
            /nix/store/**                                                      r,

            /usr/bin/python3                                                   rix,
            /usr/bin/python3.*                                                 rix,
            /nix/store/*-python3-*/bin/python3*                                rix,
            /usr/bin/env                                                       rix,
            /usr/bin/steam-runtime-launcher-interface-@{int}                   rix,

            @{app_dirs}/**                                                     mrix,
            @{app_dirs}/SteamLinuxRuntime*/**                                  mrix,
            @{config_dirs}/bin/d3ddriverquery64.exe                            mr,
            owner @{config_dirs}/steamapps/compatdata/                         rwk,
            owner @{config_dirs}/steamapps/compatdata/**                       rwlkm,
            owner @{config_dirs}/steamapps/shadercache/                        rwk,
            owner @{config_dirs}/steamapps/shadercache/**                      rwlkm,
            owner @{config_dirs}/logs/**                                       rwk,
            owner @{HOME}/.steam/steam.pipe                                    r,

            owner /bindfile*                                                   rw,
            owner /var/pressure-vessel/**                                      rw,
            owner /var/cache/ldconfig/aux-cache*                               rw,
            owner /tmp/pressure-vessel-*/                                      rwk,
            owner /tmp/pressure-vessel-*/**                                    rwlk,
            owner /tmp/glx-icds-*/                                             rwk,
            owner /tmp/glx-icds-*/**                                           w,
            owner /tmp/vdpau-drivers-*/                                        rwk,
            owner /tmp/vdpau-drivers-*/**                                      w,

            /run/host/                                                         r,
            /run/host/**                                                       r,
            /run/pressure-vessel/                                              r,
            /run/pressure-vessel/**                                            r,

            @{sys}/devices/system/node/                                        r,
            @{sys}/devices/system/node/**                                      r,
            @{PROC}/@{pid}/net/*                                               r,
            @{PROC}/sys/net/core/bpf_jit_enable                                r,

            include if exists <local/steam-game-proton>
          }
        '';
      };

      "steam-game-native" = {
        state = cfg.desktop.gaming.steam.mode;
        profile = let
          modeFlag = if cfg.desktop.gaming.steam.mode == "complain" then
            "flags=(complain, attach_disconnected, mediate_deleted)"
          else
            "flags=(attach_disconnected, mediate_deleted)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{config_dirs} = @{HOME}/.local/share/Steam
          @{libsteam_dirs} = @{config_dirs}/ubuntu12_{32,64} @{config_dirs}/linux{32,64} @{config_dirs}/steamrt{32,64}
          @{app_dirs} = @{config_dirs}/steamapps/common
          @{exec_path} = @{app_dirs}/*/**

          profile steam-game-native @{exec_path} ${modeFlag} {
            include <abstractions/base>
            include <abstractions/curios/gconv>
            include <abstractions/curios/graphics>
            include <abstractions/curios/wayland>
            include <abstractions/audio>
            include <abstractions/curios/secrets-deny>
            include <abstractions/curios/secrets-deny-browsers>

            network inet dgram,
            network inet stream,
            network inet6 dgram,
            network inet6 stream,
            network netlink raw,
            network unix stream,

            signal receive peer=steam,

            @{exec_path}                                                       mrix,
            @{app_dirs}/**                                                     mr,
            @{libsteam_dirs}/**                                                mr,
            /nix/store/*/lib{,32,64}/**.so*                                    mr,
            /nix/store/**                                                      r,

            /nix/store/*-bash-interactive-*/bin/{sh,bash}                      rix,
            /usr/bin/env                                                       rix,
            /bin/sh                                                            rix,
            /usr/bin/{cat,dash,ln,mkdir,rm,uname}                              rix,

            owner @{HOME}/.steam/steam.pipe                                    r,
            owner @{HOME}/.config/unity3d/                                     rwk,
            owner @{HOME}/.config/unity3d/**                                   rwlkm,
            owner @{HOME}/.mono/                                               rwk,
            owner @{HOME}/.mono/**                                             rwlkm,
            owner @{config_dirs}/steamapps/shadercache/                        rwk,
            owner @{config_dirs}/steamapps/shadercache/**                      rwlkm,
            owner /dev/shm/u@{uid}-Shm_*                                       rw,
            owner /dev/shm/u@{uid}-ValveIPCSharedObj-Steam                     rwk,
            owner /dev/shm/ValveIPCSHM_@{uid}                                  rw,

            include if exists <local/steam-game-native>
          }
        '';
      };
    };
  };
}
