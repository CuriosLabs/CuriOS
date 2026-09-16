# CuriOS NixOS-path AppArmor profiles.
# See pkgs.apparmor-profiles and security.apparmor options.
# `nixos-option security.lsm`, `aa-enabled`, `sudo aa-status`
# `eza -l -tree /etc/apparmor.d/`
# Useful commands:
# `sudo aa-status` `sudo aa-status --complaining`
# sudo grep "apparmor=\"DENIED\"" /var/log/audit/audit.log | grep -i brave
# sudo grep -E "apparmor=\"(ALLOWED|DENIED|ERROR)\"" /var/log/audit/audit.log
# sudo grep -E 'apparmor="(STATUS|ERROR)"' /var/log/audit/audit.log
# sudo grep -E 'seccomp|SECCOMP' /var/log/audit/audit.log
# sudo grep -E 'op=capable|capname=' /var/log/audit/audit.log | grep -iE 'sys_admin|sys_chroot|setuid|setgid'
# Clear AppArmor change when debugging:
# `sudo fd -d 1 . /var/cache/apparmor/ -E logprof -x rm -rf {} && sudo systemctl restart apparmor`
# Get current AppArmor profile mode of an app:
# `curios-update --nixos-option curios.hardened.apparmor-profiles.desktop.browsers.brave.mode`
# Change an AppArmor profile mode:
# `sudo curios-update --update-module curios.hardened.apparmor-profiles.desktop.browsers.brave.mode "complain" && sudo curios-update --update`
#
# TODO: Add AppArmor profiles in priority order:
#   Tier 1 — Chromium/Electron (render untrusted network content):
#     - cursor (Electron IDE)
#   Tier 1 — Document viewers (PDF is turing-complete: JS, fonts, 3D;
#            long CVE history; files arrive from email/web):
#     - okular / zathura (PDF viewers)
#   Tier 1 — Email clients (render HTML mail, parse MIME, open
#            attachments — classic malware delivery vector):
#     - thunderbird / geary
#   Tier 2 — Media players / codec & image parsers (codec parsing is a
#            historic buffer-overflow goldmine; e.g. CVE-2023-4863 WebP hit
#            nearly every Linux image library):
#     - mpv / ffmpeg-backed tools / image viewers
#   Tier 2 — Thumbnailers / file managers (opening a folder of untrusted
#            files silently invokes parsers for every format — a file manager
#            without a profile indirectly exposes every thumbnailer):
#     - nautilus / thunar / COSMIC files
#   Tier 2 — Archive extraction tools (zip bombs, path traversal, symlink
#            attacks — extraction runs parsers on untrusted structure):
#     - file-roller / ark
#   Tier 3 — Native editors with WebView (access SSH keys/tokens/source):
#     - zed
#   Tier 3 — Flutter/non-Electron apps with network + filesystem access:
#     - localsend
#
# TUI/CLI tools (opencode, curios-manager, nvim) do NOT need profiles — they
# operate on explicit user input, have dynamic filesystem access, and minimal
# attack surface. Profile maintenance cost outweighs security benefit.
# Package managers (Nix) are already sandboxed by design.
# References:
# https://github.com/roddhjav/apparmor.d/tree/main/apparmor.d
# https://wiki.debian.org/AppArmor/HowToUse
# https://hedgedoc.grimmauld.de/s/hWcvJEniW#
# https://hedgedoc.grimmauld.de/s/03eJUe0X3#
# https://wiki.archlinux.org/title/AppArmor

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  options.curios.hardened.apparmor-profiles = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description =
        "Ship CuriOS AppArmor profiles. Requires curios.hardened.anssi.reinforced.enable and curios.hardened.anssi.reinforced.rule45 to be enabled.";
    };

    desktop = {
      browsers = {
        brave = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "enforce";
            description = "AppArmor profile mode for Brave.";
          };
        };
      };

      chat = {
        discord = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "enforce";
            description = "AppArmor profile mode for Discord.";
          };
        };
        signal-desktop = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "enforce";
            description = "AppArmor profile mode for Signal Desktop.";
          };
        };
      };

      gaming = {
        steam = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "complain";
            description = "AppArmor profile mode for Steam.";
          };
        };
      };

      office = {
        evince = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "enforce";
            description =
              "AppArmor profile mode for Evince (viewer, previewer, daemon, thumbnailer).";
          };
        };
        onlyoffice = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "enforce";
            description =
              "AppArmor profile mode for OnlyOffice desktop editors.";
          };
        };
      };
    };
  };

  config = mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.includes = {
      "abstractions/curios/camera" = ''
        abi <abi/4.0>,
        # Allows access to all cameras
        # Camera (video calls, webcam)
        /dev/video*  rw,
      '';

      "abstractions/curios/dconf" = ''
        abi <abi/4.0>,
        # COSMIC dconf paths (upstream abstractions/dconf only covers
        # dconf/user). Parent dir 'w' allows creating the db file.
        owner @{run}/user/@{uid}/dconf/        rwk,
        owner @{run}/user/@{uid}/dconf/cosmic  rwk,
        owner @{HOME}/.config/dconf/cosmic     r,
      '';

      "abstractions/curios/devices" = ''
        abi <abi/4.0>,
        # System config
        /etc/machine-id                              r,
        #@{sys}/devices/**                           r,
        @{sys}/devices/system/cpu/**                 r,

        # Hardware detection (GPU/PCI/USB enumeration, active tty, DMI info)
        # Wide allocations are for Chromium hardware fingerprinting
        # (captcha API enumerates all visible buses and device classes)
        /dev/                                        r,
        @{sys}/bus/                                  r,
        @{sys}/bus/*/devices/                        r,
        @{sys}/bus/pci/devices/                      r,
        @{sys}/bus/usb/devices/                      r,
        @{sys}/class/                                r,
        @{sys}/class/*/                              r,
        @{sys}/devices/pci*/**                       r,
        @{sys}/devices/platform/**                   r,
        @{sys}/devices/virtual/tty/tty0/active       r,
        @{sys}/devices/virtual/dmi/id/sys_vendor     r,
        @{sys}/devices/virtual/dmi/id/product_name   r,
        @{sys}/devices/virtual/dmi/id/board_vendor   r,
        @{sys}/devices/virtual/dmi/id/bios_vendor    r,
        @{sys}/devices/**/uevent                     r,
        @{run}/udev/data/*                           r,
        # Disk enumeration (download location detection)
        /dev/disk/by-uuid/                           r,
        # Disk enumeration (save/open file dialog)
        /dev/disk/by-label/                          r,
      '';

      "abstractions/curios/gconv" = ''
        abi <abi/4.0>,
        # glibc charset conversion module
        ${pkgs.glibc}/lib/gconv/*.so               mr,
        ${pkgs.glibc}/lib/gconv/gconv-modules      mr,
        ${pkgs.glibc}/lib/gconv/gconv-modules.d/   r,
        ${pkgs.glibc}/lib/gconv/gconv-modules.d/*  mr,
      '';

      "abstractions/curios/graphics" = ''
        abi <abi/4.0>,
        # NixOS-aware GPU stack for WebGL/WebGL2 (Mesa + Vulkan + DRI).
        # dri-common is exported under /etc/apparmor.d/abstractions/; mesa and
        # dri-enumerate are not, so pin them to pkgs.apparmor-profiles.
        # mesa already includes dri-common + dri-enumerate + shader caches.
        include <abstractions/dri-common>
        include "${pkgs.apparmor-profiles}/etc/apparmor.d/abstractions/dri-enumerate"
        include "${pkgs.apparmor-profiles}/etc/apparmor.d/abstractions/mesa"
        include "${pkgs.apparmor-profiles}/etc/apparmor.d/abstractions/vulkan"

        # Extra GPU nodes (not always covered / needed on AMD)
        /dev/kfd                                                      rw,
        /dev/shm/                                                     r,

        # NixOS graphics drivers (Mesa/Vulkan ICDs, Gallium, GBM)
        # Upstream abstractions only cover FHS /usr/lib and /usr/share paths.
        /run/opengl-driver/                                           r,
        /run/opengl-driver/**                                         mr,
        /run/opengl-driver-32/                                        r,
        /run/opengl-driver-32/**                                      mr,

        # Vulkan ICD/layer discovery under the NixOS driver tree
        /run/opengl-driver/share/vulkan/icd.d/{,*.json}               r,
        /run/opengl-driver/share/vulkan/{explicit,implicit}_layer.d/{,*.json} r,

        # AMD GPU identity table (libdrm; FHS path is /usr/share/libdrm/)
        /nix/store/*-libdrm-*/share/libdrm/amdgpu.ids                 r,
      '';

      "abstractions/curios/nss" = ''
        abi <abi/4.0>,
        # NSS certificate database (client certificates, CA trust)
        owner @{HOME}/.pki/nssdb/                        rw,
        owner @{HOME}/.pki/nssdb/pkcs11.txt              rw,
        owner @{HOME}/.pki/nssdb/{cert9,key4}.db         rwk,
        owner @{HOME}/.pki/nssdb/{cert9,key4}.db-journal rw,
      '';

      "abstractions/curios/wine" = ''
        abi <abi/4.0>,
        /dev/ntsync                                      r,
        owner /tmp/.wine-@{uid}/                         rwk,
        owner /tmp/.wine-@{uid}/**                       rwkm,
        owner /tmp/protonfixes_test.log                  w,
        owner /tmp/protonfixes-gtk-*/                    rwk,
        owner /tmp/protonfixes-gtk-*/**                  rw,
        owner @{HOME}/.cache/protonfixes/                rwk,
        owner @{HOME}/.cache/protonfixes/**              rwk,
        owner @{HOME}/.local/share/applications/wine/    rwk,
        owner @{HOME}/.local/share/applications/wine/**  rwk,
        owner /dev/shm/wine-*                            rw,
      '';

      "abstractions/curios/secrets-deny" = ''
        abi <abi/4.0>,
        deny @{HOME}/.ssh/**                             r,
        deny @{HOME}/.gnupg/**                           r,
        deny @{HOME}/.password-store/**                  r,
        deny @{HOME}/.aws/**                             r,
        deny @{HOME}/.azure/**                           r,
        deny @{HOME}/.config/gcloud/**                   r,
        deny @{HOME}/.kube/**                            r,
        deny @{HOME}/.docker/config.json                 r,
        deny @{HOME}/.netrc                              r,
        deny @{HOME}/.npmrc                              r,
        deny @{HOME}/.pypirc                             r,
        deny @{HOME}/.git-credentials                    r,
        deny @{HOME}/.config/gh/**                       r,
        deny @{HOME}/.config/git/**                      r,
        deny @{HOME}/.local/share/keyrings/**            r,
        deny @{HOME}/.config/keepassxc/**                r,
        deny @{HOME}/.config/Bitwarden/**                r,
        deny @{HOME}/.config/1Password/**                r,
        deny @{HOME}/.electrum/**                        r,
        deny @{HOME}/.bitcoin/**                         r,
        deny @{HOME}/.ethereum/**                        r,
        deny @{HOME}/.monero/**                          r,
        deny @{HOME}/.config/solana/**                   r,
        deny "@{HOME}/.config/Ledger Live/**"            r,
        deny @{HOME}/.config/Exodus/**                   r,
        deny @{HOME}/.local/share/Exodus/**              r,
        deny @{HOME}/**/.env                             r,
        deny @{HOME}/**/.env.*                           r,
        deny @{HOME}/**/.envrc                           r,
        deny @{HOME}/**/id_{rsa,ed25519,ecdsa,dsa}       r,
        deny @{HOME}/**/*.pem                            r,
        deny @{HOME}/**/*.kdbx                           r,
      '';

      "abstractions/curios/secrets-deny-browsers" = ''
        abi <abi/4.0>,
        deny @{HOME}/.mozilla/**                         r,
        deny @{HOME}/.config/BraveSoftware/**            r,
        deny @{HOME}/.config/chromium/**                 r,
        deny @{HOME}/.config/google-chrome/**            r,
      '';

      "abstractions/curios/wayland" = ''
        abi <abi/4.0>,
        # Needed when using QT_QPA_PLATFORM=wayland-egl (MESA dri config)
        /etc/drirc r,

        # Allow access to the Wayland compositor server socket
        owner @{run}/user/@{uid}/wayland-@{int}               rw,
        owner @{run}/user/@{uid}/wayland-@{int}.lock          rwk,
        owner @{run}/user/@{uid}/wayland-cursor-shared-@{int} rw,
        owner @{run}/user/@{uid}/wayland-proxy-@{int}         rw,

        # Compositors specific socket path
        owner @{run}/user/@{uid}/.mutter-Xwaylandauth.@{rand6} r,
        owner @{run}/user/@{uid}/mesa-shared-@{int}            rw,
        owner @{run}/user/@{uid}/mutter-shared-@{int}          rw,
        owner @{run}/user/@{uid}/sdl-shared-@{int}             rw,
        owner @{run}/user/@{uid}/weston-shared-@{int}          rw,
        owner @{run}/user/@{uid}/xwayland-shared-@{int}        rw,

        # Compositors based on wlroots
        #owner /dev/shm/@{uuid}         rw,
        owner /dev/shm/dunst-@{rand6}   rw,
        owner /dev/shm/grim-@{rand6}    rw,
        owner /dev/shm/sway*            rw,
        owner /dev/shm/wlroots-@{rand6} rw,
      '';

      "abstractions/curios/evince" = ''
        abi <abi/4.0>,
        # CuriOS common abstraction for Evince on NixOS.
        # Inspired by apparmor.d evince / evince-thumbnailer and the Ubuntu
        # evince abstraction, rewritten for NixOS store paths and CuriOS
        # abstractions (no FHS /usr/share, no ubuntu-* helpers).
        #
        # Shared by evince, evince-previewer, evinced, and evince-thumbnailer.

        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/consoles>
        include <abstractions/fonts>
        include <abstractions/dconf>
        include <abstractions/cups-client>
        include <abstractions/curios/dconf>
        include <abstractions/curios/gconv>
        include <abstractions/curios/graphics>
        include <abstractions/curios/wayland>
        include <abstractions/curios/secrets-deny>
        include <abstractions/curios/secrets-deny-browsers>

        /nix/store/*/lib{,32,64}/**.so*                                        mr,
        /nix/store/**                                                          r,

        ${pkgs.evince}/bin/evince                                              mr,
        ${pkgs.evince}/bin/.evince-wrapped                                     mr,
        ${pkgs.evince}/bin/evince-previewer                                    mr,
        ${pkgs.evince}/bin/.evince-previewer-wrapped                           mr,
        ${pkgs.evince}/libexec/evinced                                         mr,
        ${pkgs.evince}/libexec/.evinced-wrapped                                mr,
        ${pkgs.evince}/lib/*.so*                                               mr,
        ${pkgs.evince}/lib/evince/**                                           mr,
        ${pkgs.evince}/share/evince/**                                         r,
        ${pkgs.evince}/share/thumbnailers/**                                   r,

        ${pkgs.glib.out}/libexec/gio-launch-desktop                            rix,
        ${pkgs.bashInteractive}/bin/sh                                         rix,
        ${pkgs.bashInteractive}/bin/bash                                       rix,
        ${pkgs.coreutils-full}/bin/*                                           rix,
        ${pkgs.coreutils}/bin/*                                                rix,

        ${pkgs.gzip}/bin/gzip                                                  rix,
        ${pkgs.bzip2}/bin/bzip2                                                rix,
        ${pkgs.xz}/bin/xz                                                      rix,
        ${pkgs.gnutar}/bin/tar                                                 rix,
        ${pkgs.unzip}/bin/unzip                                                rix,
        ${pkgs.p7zip}/bin/{7z,7za,7zr}                                         rix,
        ${pkgs.ghostscript}/bin/gs                                             rix,

        owner @{HOME}/.config/evince/                                          rwk,
        owner @{HOME}/.config/evince/**                                        rwkl,
        owner @{HOME}/.cache/evince/                                           rwk,
        owner @{HOME}/.cache/evince/**                                         rwk,
        owner @{HOME}/.config/gtk-3.0/**                                       r,
        owner @{HOME}/.config/gtk-4.0/**                                       r,
        owner @{HOME}/.config/glib-2.0/                                        rwk,
        owner @{HOME}/.config/glib-2.0/**                                      rwk,
        owner @{HOME}/.config/user-dirs.dirs                                   r,
        owner @{HOME}/.config/mimeapps.list                                    r,
        owner @{HOME}/.config/cosmic-mimeapps.list                             r,
        owner @{HOME}/.local/share/                                            r,
        owner @{HOME}/.local/share/applications/                               r,
        owner @{HOME}/.local/share/applications/**                             r,
        owner @{HOME}/.local/share/mime/                                       r,
        owner @{HOME}/.local/share/mime/**                                     r,
        owner @{HOME}/.local/share/icons/                                      r,
        owner @{HOME}/.local/share/icons/**                                    r,
        owner @{HOME}/.local/share/gvfs-metadata/*                             r,
        owner @{HOME}/.local/share/recently-used.xbel                          rwk,
        owner @{HOME}/.local/share/recently-used.xbel.*                        rwk,
        owner @{HOME}/.cache/thumbnails/                                       rwk,
        owner @{HOME}/.cache/thumbnails/**                                     rwk,
        /var/lib/flatpak/exports/share/icons/                                  r,
        /var/lib/flatpak/exports/share/icons/**                                r,
        /var/lib/flatpak/exports/share/applications/                           r,
        /var/lib/flatpak/exports/share/applications/**                         r,

        owner @{run}/user/@{uid}/bus                                           rw,
        owner @{PROC}/@{pid}/fd/                                               r,
        owner @{PROC}/@{pid}/mountinfo                                         r,
        owner @{PROC}/@{pid}/mounts                                            r,
        owner @{PROC}/@{pid}/status                                            r,

        /                                                                      r,
        /tmp/                                                                  r,
        /run/media/                                                            r,
        /dev/tty                                                               rw,
        /etc/papersize                                                         r,
        /etc/fstab                                                             r,
      '';

      "abstractions/curios/chromium-engine" = ''
        abi <abi/4.0>,
        # CuriOS common abstraction for Chromium/Electron engine sandboxing
        # on NixOS. Provides baseline AppArmor rules shared by Chromium-based
        # browsers and Electron-based applications.
        #
        # REQUIRED VARIABLES (define in the calling profile header, before this include):
        #   @{config_dirs} — app config directory
        #   @{cache_dirs}  — app cache directory

        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/audio>
        include <abstractions/consoles>
        include <abstractions/cups-client>
        include <abstractions/fonts>
        include <abstractions/dconf>
        include <abstractions/ssl_certs>
        include <abstractions/curios/dconf>
        include <abstractions/curios/devices>
        include <abstractions/curios/gconv>
        include <abstractions/curios/graphics>
        include <abstractions/curios/nss>
        include <abstractions/curios/wayland>
        include <abstractions/curios/secrets-deny>

        # NixOS shared libraries. Upstream abstractions/base only grants
        # access to FHS paths (/{usr/,}lib{,32,64}/*.so*); on NixOS every
        # library lives in /nix/store and must be allowed explicitly.
        /nix/store/*/lib{,32,64}/**.so*                                        mr,

        # Chromium sandbox. On NixOS the nix store is read-only so
        # chrome-sandbox cannot be SUID 4755. Chromium must use unprivileged
        # user namespaces instead. `userns` allows unshare(CLONE_NEWUSER);
        # `capability sys_admin` is required for subsequent PID/network
        # namespace creation within the user namespace sandbox;
        # `capability sys_chroot` is required by the zygote process to
        # chroot sandboxed children into their namespace.
        # sys_ptrace: Chromium crash handler inspects child processes.
        # mknod: needed to create temp files (.crdownload, shared memory)
        userns,
        capability sys_admin,
        capability sys_chroot,
        capability sys_ptrace,
        capability mknod,

        # Shell and utilities for NixOS wrapper scripts
        ${pkgs.bashInteractive}/bin/sh                                         rix,
        ${pkgs.bashInteractive}/bin/bash                                       rix,

        # Network access
        network inet dgram,
        network inet6 dgram,
        network inet stream,
        network inet6 stream,
        network netlink raw,

        # User config and cache (uses variables from calling profile).
        # 'm' (mmap) needed for WidevineCdm .so loaded from config dir.
        # Parent directory 'r' needed for directory listing (e.g.
        # BraveSoftware/ must be listable to find Brave-Browser/).
        owner @{config_dirs}/                                                  r,
        owner @{config_dirs}/**                                                rwkm,
        owner @{cache_dirs}/                                                   r,
        owner @{cache_dirs}/**                                                 rwkm,

        # Temporary files. /tmp/ directory listing needed by Chromium.
        /tmp/                                                                  r,
        # Root directory listing (filesystem enumeration)
        /                                                                      r,
        # Chromium creates shared-memory files and dirs
        # in /tmp/.org.chromium.Chromium.* — 'rwk' on the file pattern allows
        # mknod+read of top-level files, 'wk' on */ allows mkdir of dirs,
        # 'rwkm' on /** covers contents.
        owner /tmp/.org.chromium.Chromium.*                                    rwk,
        owner /tmp/.org.chromium.Chromium.*/                                   rwk,
        owner /tmp/.org.chromium.Chromium.*/**                                 rwkm,
        # Brave uses a variant without the leading dot
        owner /tmp/org.chromium.Chromium.*                                     rwk,
        owner /tmp/org.chromium.Chromium.*/                                    rwk,
        owner /tmp/org.chromium.Chromium.*/**                                  rwkm,
        # Chromium scoped temp dirs (file picker, downloads, plugins).
        owner /tmp/scoped_dir*/                                                rwk,
        owner /tmp/scoped_dir*/**                                              rwkm,
        owner @{HOME}/.tmp/**                                                  rw,

        # /proc access for Chromium sandbox
        owner @{PROC}/@{pid}/fd/                                               r,
        owner @{PROC}/@{pid}/fd/@{int}                                         w,
        owner @{PROC}/@{pid}/maps                                              r,
        owner @{PROC}/@{pid}/stat                                              r,
        owner @{PROC}/@{pid}/status                                            r,
        owner @{PROC}/@{pid}/task/                                             r,
        owner @{PROC}/@{pid}/task/@{tid}/comm                                  rw,
        owner @{PROC}/@{pid}/cmdline                                           r,
        owner @{PROC}/@{pid}/environ                                           r,
        owner @{PROC}/@{pid}/oom_adj                                           r,
        owner @{PROC}/@{pid}/oom_score_adj                                     rw,
        owner @{PROC}/@{pid}/cgroup                                            r,
        owner @{PROC}/@{pid}/mounts                                            r,
        owner @{PROC}/@{pid}/mountinfo                                         r,
        owner @{PROC}/@{pid}/smaps_rollup                                      r,
        owner @{PROC}/@{pid}/limits                                            r,
        @{PROC}/                                                               r,
        @{PROC}/sys/kernel/yama/ptrace_scope                                   r,
        # Kernel version (read by xdg scripts via grep)
        @{PROC}/version                                                        r,
        # Pressure Stall Information (Chromium resource monitoring)
        @{PROC}/pressure/                                                      r,
        @{PROC}/pressure/{cpu,io,memory}                                       r,

        # Chromium processes read each other's proc info (parent reads
        # child stats, ThreadPool reads sibling thread status). These must
        # be non-owner since the reading process differs from the target.
        @{PROC}/@{pid}/stat                                                    r,
        @{PROC}/@{pid}/task/@{tid}/status                                      r,
        @{PROC}/@{pid}/comm                                                    r,
        @{PROC}/@{pid}/statm                                                   r,
        # Memory profiling (Chromium memory infrastructure)
        owner @{PROC}/@{pid}/clear_refs                                        w,

        # User namespace setup. On NixOS the nix store is read-only so
        # chrome-sandbox cannot be SUID 4755. Chromium must use unprivileged
        # user namespaces instead, which requires writing uid/gid mappings.
        owner @{PROC}/@{pid}/uid_map                                           rw,
        owner @{PROC}/@{pid}/gid_map                                           rw,
        owner @{PROC}/@{pid}/setgroups                                         rw,

        # inotify limits (Chromium file watcher)
        @{PROC}/sys/fs/inotify/max_user_watches                                r,
        @{PROC}/sys/fs/inotify/max_queued_events                               r,
        @{PROC}/sys/fs/inotify/max_user_instances                              r,

        # Chromium shared memory
        /dev/shm/.org.chromium.Chromium.* rw,

        # D-Bus
        owner @{run}/user/@{uid}/bus                                           rw,

        # cgroup CPU limits (Chromium resource monitoring)
        @{sys}/fs/cgroup/**                                                    r,

        # GTK
        owner @{HOME}/.config/gtk-3.0/**                                       r,
        owner @{HOME}/.config/gtk-4.0/**                                       r,
        # GLib config (GSettings schema cache)
        owner @{HOME}/.config/glib-2.0/                                        rwk,
        owner @{HOME}/.config/glib-2.0/**                                      rwk,

        # XDG user directories (used by file dialogs, download paths)
        owner @{HOME}/.config/user-dirs.dirs                                   r,
        # Non-hidden top-level home dirs only (Documents, Downloads, …).
        # [^.]* excludes ~/.ssh, ~/.gnupg, ~/.config, etc. AppArmor can't
        # follow real XDG user-dirs at policy load time, so any non-hidden
        # top-level directory is allowed. Nested hidden files (e.g.
        # ~/Documents/.something) are still covered by /**.
        owner @{HOME}/[^.]*/                                                   rwk,
        owner @{HOME}/[^.]*/**                                                 rwkm,
        # Chromium temp download files
        owner @{HOME}/[^.]*/**/*.crdownload                                    rwkm,
        # XDG MIME associations and application listings
        owner @{HOME}/.config/mimeapps.list                                    r,
        owner @{HOME}/.config/cosmic-mimeapps.list                             r,
        owner @{HOME}/.local/share/applications/                               r,
        owner @{HOME}/.local/share/applications/**                             r,

        # Open links in default browser. xdg-open inherits the caller's profile
        # so the exec must be allowed here. Transitions to Brave's own profile.
        ${pkgs.brave}/bin/brave                                                rPx -> brave-wrapper,

        # XDG utilities (default browser check, URL opening). xdg scripts
        # use shell utilities (grep, sed, awk, etc.) which inherit the
        # browser profile, so they must be allowed for exec.
        ${pkgs.xdg-utils}/bin/xdg-settings                                     rix,
        ${pkgs.xdg-utils}/bin/xdg-open                                         rix,
        ${pkgs.xdg-utils}/bin/xdg-mime                                         rix,
        /run/current-system/sw/bin/xdg-settings                                rix,
        /run/current-system/sw/bin/xdg-open                                    rix,
        /run/current-system/sw/bin/xdg-mime                                    rix,
        # Shell utilities used by xdg scripts and wrapper scripts
        ${pkgs.coreutils-full}/bin/*                                           rix,
        ${pkgs.coreutils}/bin/*                                                rix,
        ${pkgs.gnugrep}/bin/grep                                               rix,
        ${pkgs.gnused}/bin/sed                                                 rix,
        ${pkgs.gawk}/bin/{awk,gawk}                                            rix,
        ${pkgs.findutils}/bin/find                                             rix,
        /run/current-system/sw/bin/{grep,sed,awk,find}                         rix,
        # D-Bus and X11 utilities used by xdg-settings
        ${pkgs.dbus}/bin/dbus-send                                             rix,
        ${pkgs.xprop}/bin/xprop                                                rix,

        # NixOS shared resources. On NixOS fonts, gsettings schemas, icon
        # themes, translations, xkb config, fontconfig caches, GDK pixbuf
        # loaders etc. live in /nix/store/ rather than /usr/share/ and
        # /etc/fonts/. Upstream abstractions only cover FHS paths.
        # The nix store is world-readable by design, so granting read
        # access to it is not a meaningful security boundary on NixOS —
        # equivalent to /usr/share/** r on FHS distros.
        /nix/store/**                                                          r,

        # Icons, themes, shared data
        @{HOME}/.local/share/icons/                                            r,
        @{HOME}/.local/share/icons/**                                          r,
        @{HOME}/.local/share/themes/                                           r,
        @{HOME}/.local/share/themes/**                                         r,
        @{HOME}/.local/share/mime/                                             r,
        @{HOME}/.local/share/mime/**                                           r,
        # Flatpak-exported icons/themes/applications
        /var/lib/flatpak/exports/share/icons/                                  r,
        /var/lib/flatpak/exports/share/icons/**                                r,
        /var/lib/flatpak/exports/share/themes/                                 r,
        /var/lib/flatpak/exports/share/themes/**                               r,
        /var/lib/flatpak/exports/share/applications/                           r,
        /var/lib/flatpak/exports/share/applications/**                         r,

        # Removable media (USB drives, SD cards, external storage)
        /run/media/                                                           r,
        /run/media/**                                                         r,

        # Silencer
        deny /etc/opt/                                                         w,
        deny @{HOME}/.local/share/gvfs-metadata/*                              r,
      '';

      "abstractions/curios/fhsenv-bwrap" = ''
        abi <abi/4.0>,
        # CuriOS common abstraction for NixOS buildFHSEnv / bubblewrap apps.
        # Covers the shared bwrap bootstrap chain used by every FHSEnv package:
        #   app-bwrap script → bwrap → container-init → {name}-init → app
        #
        # REQUIRED VARIABLES (define in the calling profile header, before this include):
        #   @{lib_dirs} — FHSEnv rootfs path (e.g. {pkgs.foo.fhsenv})
        #
        # App-specific pieces stay in the calling profile:
        #   - {name}-init script (not on passthru; keep store glob)
        #   - app binaries / share / modules
        #   - network, config/cache dirs, desktop abstractions

        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/consoles>
        include <abstractions/fonts>
        include <abstractions/dconf>
        include <abstractions/ssl_certs>
        include <abstractions/curios/devices>
        include <abstractions/curios/gconv>

        # Static container-init shim (shared across all FHSEnv packages;
        # runs ldconfig then execs /init). Not exposed via pkgs.*.
        /nix/store/*-container-init                                            rix,
        ${pkgs.glibc.bin}/bin/ldconfig                                         rix,

        # Bubblewrap binary and shell helpers used by the *-bwrap launcher
        ${pkgs.bubblewrap}/bin/bwrap                                           rix,
        ${pkgs.bashInteractive}/bin/sh                                         rix,
        ${pkgs.bashInteractive}/bin/bash                                       rix,
        ${pkgs.coreutils-full}/bin/*                                           rix,
        ${pkgs.coreutils}/bin/*                                                rix,

        # FHSEnv rootfs (bind-mounted into the namespace as /usr, /lib, …)
        @{lib_dirs}/                                                           r,
        @{lib_dirs}/**                                                         mr,

        # Nix store — FHSEnv rootfs is mostly symlinks into the store;
        # mmap needed for shared libraries loaded inside the namespace.
        /nix/store/**                                                          r,
        /nix/store/*/lib{,32,64}/**.so*                                        mr,

        # bwrap namespace bootstrap: mount/mkdir/symlink/mknod under
        # /newroot/, /oldroot/, /tmp/ and pivot into the FHS tree.
        # Intentionally NOT "owner /**" — that would grant full $HOME
        # including ~/.ssh, ~/.gnupg, etc.
        /                                                                      r,
        owner /tmp/                                                            rwk,
        owner /tmp/**                                                          rwk,
        owner /newroot/                                                        rwk,
        owner /newroot/**                                                      rwk,
        owner /oldroot/                                                        rwk,
        owner /oldroot/**                                                      rwk,
        owner /dev/shm/                                                        rwk,
        owner /dev/shm/**                                                      rwk,
        # Non-hidden top-level home dirs only (Documents, Downloads, …).
        # [^.]* excludes ~/.ssh, ~/.gnupg, ~/.config, etc. Nested hidden
        # files under normal dirs remain allowed via /**.
        owner @{HOME}/[^.]*/                                                   rwk,
        owner @{HOME}/[^.]*/**                                                 rwkm,
        mount,
        umount,
        pivot_root,

        # User namespace setup (unprivileged bwrap on NixOS)
        userns,
        capability setpcap,
        capability sys_admin,
        capability sys_chroot,
        capability sys_ptrace,
        capability mknod,

        # Proc (uid/gid maps, mountinfo, fd for bwrap)
        @{PROC}/                                                               r,
        owner @{PROC}/@{pid}/fd/                                               r,
        owner @{PROC}/@{pid}/fd/@{int}                                         w,
        owner @{PROC}/@{pid}/uid_map                                           rw,
        owner @{PROC}/@{pid}/gid_map                                           rw,
        owner @{PROC}/@{pid}/setgroups                                         rw,
        owner @{PROC}/@{pid}/mountinfo                                         r,
        @{PROC}/@{pid}/stat                                                    r,
        @{PROC}/sys/kernel/overflow{uid,gid}                                   r,
        @{PROC}/sys/fs/inotify/max_user_watches                                r,

        # Paths visible inside the FHS namespace (root-owned bind mounts)
        /usr/**                                                                r,
        /.host-etc/**                                                          r,
        /etc/resolv.conf                                                       r,
      '';

      "abstractions/electron" = ''
        abi <abi/4.0>,
        # CuriOS common abstraction for Electron-based applications on NixOS.
        # The Electron runtime is shared across all Electron apps via
        # /nix/store/*-electron-unwrapped-* — only the app.asar/resources differ.
        #
        # REQUIRED VARIABLES (define in the calling profile header, before this include):
        #   @{config_dirs} — app config directory  (e.g. @{HOME}/.config/Signal)
        #   @{cache_dirs}  — app cache directory   (e.g. @{HOME}/.cache/signal-desktop)

        include <abstractions/curios/chromium-engine>
        include <abstractions/curios/dconf>

        # Electron exec chain: app wrapper → electron wrapper → electron binary (shared)
        ${pkgs.electron}/bin/electron                                          rix,
        ${pkgs.electron.unwrapped}/libexec/electron/electron                   mrix,
        ${pkgs.electron.unwrapped}/libexec/electron/chrome_crashpad_handler    rix,
        ${pkgs.electron_42}/bin/electron                                       rix,
        ${pkgs.electron_42.unwrapped}/libexec/electron/electron                mrix,
        ${pkgs.electron_42.unwrapped}/libexec/electron/chrome_crashpad_handler rix,
        ${pkgs.electron_43}/bin/electron                                       rix,
        ${pkgs.electron_43.unwrapped}/libexec/electron/electron                mrix,
        ${pkgs.electron_43.unwrapped}/libexec/electron/chrome_crashpad_handler rix,


        # Electron libraries and resources
        ${pkgs.electron.unwrapped}/libexec/electron/*.so*                      mr,
        ${pkgs.electron.unwrapped}/libexec/electron/*.pak                      r,
        ${pkgs.electron.unwrapped}/libexec/electron/*.dat                      r,
        ${pkgs.electron.unwrapped}/libexec/electron/*.bin                      r,
        ${pkgs.electron.unwrapped}/libexec/electron/locales/**                 r,
        ${pkgs.electron.unwrapped}/libexec/electron/resources/**               r,
        ${pkgs.electron.unwrapped}/libexec/electron/vk_swiftshader_icd.json    r,
        ${pkgs.electron_42.unwrapped}/libexec/electron/*.so*                   mr,
        ${pkgs.electron_42.unwrapped}/libexec/electron/*.pak                   r,
        ${pkgs.electron_42.unwrapped}/libexec/electron/*.dat                   r,
        ${pkgs.electron_42.unwrapped}/libexec/electron/*.bin                   r,
        ${pkgs.electron_42.unwrapped}/libexec/electron/locales/**              r,
        ${pkgs.electron_42.unwrapped}/libexec/electron/resources/**            r,
        ${pkgs.electron_42.unwrapped}/libexec/electron/vk_swiftshader_icd.json r,
        ${pkgs.electron_43.unwrapped}/libexec/electron/*.so*                   mr,
        ${pkgs.electron_43.unwrapped}/libexec/electron/*.pak                   r,
        ${pkgs.electron_43.unwrapped}/libexec/electron/*.dat                   r,
        ${pkgs.electron_43.unwrapped}/libexec/electron/*.bin                   r,
        ${pkgs.electron_43.unwrapped}/libexec/electron/locales/**              r,
        ${pkgs.electron_43.unwrapped}/libexec/electron/resources/**            r,
        ${pkgs.electron_43.unwrapped}/libexec/electron/vk_swiftshader_icd.json r,


        # PipeWire
        owner @{run}/user/*/pipewire-*                                         rw,
      '';

      "abstractions/chromium" = ''
        abi <abi/4.0>,
        # CuriOS common abstraction for Chromium-based browsers on NixOS.
        # Inspired by https://github.com/roddhjav/apparmor.d/blob/main/apparmor.d/abstractions/app/chromium
        #
        # REQUIRED VARIABLES (define in the calling profile header, before this include):
        #   @{lib_dirs}    — browser library/binary directory
        #                    (e.g. /nix/store/*-brave*/opt/brave.com/brave)
        #   @{config_dirs} — user config directory (e.g. @{HOME}/.config/BraveSoftware)
        #   @{cache_dirs}  — user cache directory  (e.g. @{HOME}/.cache/BraveSoftware)

        include <abstractions/curios/chromium-engine>
        include <abstractions/curios/camera>

        # Browser libraries, resources, and Widevine DRM
        @{lib_dirs}/{,**}                           r,
        @{lib_dirs}/*.so*                           mr,
        @{lib_dirs}/WidevineCdm/**                  mrwk,

        # Chromium policies
        /etc/chromium/policies/                     r,
        /etc/chromium/policies/**                   r,
      '';

    };

    security.apparmor.policies = {
      "brave" = {
        state = cfg.desktop.browsers.brave.mode;
        profile = let
          modeFlag = if cfg.desktop.browsers.brave.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{lib_dirs} = ${pkgs.brave}/opt/brave.com/brave
          @{config_dirs} = @{HOME}/.config/BraveSoftware
          @{cache_dirs} = @{HOME}/.cache/BraveSoftware

          profile brave ${pkgs.brave}/opt/brave.com/brave/brave ${modeFlag} {
            include <abstractions/chromium>

            # Brave binary exec chain (chrome-sandbox transitions to the
            # brave-sandbox profile; crashpad/management-service inherit)
            @{lib_dirs}/brave                       mrix,
            @{lib_dirs}/chrome-sandbox              rPx,
            @{lib_dirs}/chrome_crashpad_handler     rix,
            @{lib_dirs}/chrome-management-service   rix,

            # Brave-specific temporary files
            /tmp/.com.brave.Brave.*/**              rw,

            # Browser policies (Brave/Chromium system-managed policies)
            /etc/brave/policies/                    r,
            /etc/brave/policies/**                  r,
          }
        '';
      };

      "brave-sandbox" = {
        state = cfg.desktop.browsers.brave.mode;
        profile = ''
          abi <abi/4.0>,
          include <tunables/global>

          profile brave-sandbox ${pkgs.brave}/opt/brave.com/brave/chrome-sandbox {
            include <abstractions/base>
            include <abstractions/curios/gconv>

            # NixOS shared libraries (see abstractions/chromium for rationale)
            /nix/store/*/lib{,32,64}/**.so*                  mr,

            capability setgid,
            capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability sys_resource,

            ${pkgs.brave}/opt/brave.com/brave/chrome-sandbox mr,
            ${pkgs.brave}/opt/brave.com/brave/brave          rPx,

            @{PROC}                                          r,
            @{PROC}/@{pids}/                                 r,
            owner @{PROC}/@{pid}/fd/                         r,
            owner @{PROC}/@{pid}/oom_adj                     rw,
            owner @{PROC}/@{pid}/oom_score_adj               rw,

            include if exists <local/brave-sandbox>
          }
        '';
      };

      "brave-wrapper" = {
        state = cfg.desktop.browsers.brave.mode;
        profile = ''
          abi <abi/4.0>,
          include <tunables/global>

          profile brave-wrapper ${pkgs.brave}/bin/brave {
            include <abstractions/base>
            include <abstractions/consoles>
            include <abstractions/curios/gconv>

            # NixOS shared libraries (see abstractions/chromium for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                    mr,

            ${pkgs.brave}/bin/**                                               r,

            # Shell and coreutils for the NixOS wrapper script. The wrapper
            # calls readlink, dirname, mkdir, touch, cat via system PATH
            # (/run/current-system/sw/bin/), which symlinks to the coreutils
            # multicall binary. AppArmor resolves symlinks, so we must allow
            # the coreutils binary itself (rix = read+inherit+exec).
            ${pkgs.bashInteractive}/bin/sh                                     rix,
            ${pkgs.bashInteractive}/bin/bash                                   rix,
            ${pkgs.coreutils-full}/bin/*                                       rix,
            ${pkgs.coreutils}/bin/*                                            rix,
            /run/current-system/sw/bin/{readlink,dirname,mkdir,touch,cat}      rix,

            ${pkgs.brave}/opt/brave.com/brave/brave                            rPx,
            ${pkgs.brave}/opt/brave.com/brave/brave-browser                    rix,

            owner @{PROC}/@{pid}/fd/@{int}                                     w,

            include if exists <local/brave-wrapper>
          }
        '';
      };

      "signal-desktop" = {
        state = cfg.desktop.chat.signal-desktop.mode;
        profile = let
          modeFlag = if cfg.desktop.chat.signal-desktop.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{config_dirs} = @{HOME}/.config/Signal
          @{cache_dirs} = @{HOME}/.cache/signal-desktop

          profile signal-desktop ${pkgs.signal-desktop}/bin/signal-desktop ${modeFlag} {
            include <abstractions/electron>
            include <abstractions/curios/camera>
            include <abstractions/curios/secrets-deny-browsers>

            # Signal Desktop wrapper (inherits profile through electron exec chain)
            ${pkgs.signal-desktop}/bin/signal-desktop                          rix,

            # Chromium sandbox (separate profile with elevated capabilities)
            ${pkgs.electron_43}/libexec/electron/chrome-sandbox                rPx -> signal-desktop-chrome-sandbox,

            # Signal Desktop app resources
            ${pkgs.signal-desktop}/share/signal-desktop/**                     r,
            ${pkgs.signal-desktop}/share/signal-desktop/app.asar               mr,
            # Native node modules (libsignal crypto, ringrtc WebRTC) — need mmap
            ${pkgs.signal-desktop}/share/signal-desktop/app.asar.unpacked/**/*.node mr,

            # Signal Desktop flags
            owner @{HOME}/.config/signal-desktop-flags.conf                    r,

            # Temporary files
            /tmp/signal-desktop-*/**                                           rw,

            # Bluetooth observe (for nearby device discovery)
            @{sys}/class/bluetooth/                                            r,
            @{run}/bluetooth/**                                                r,

            include if exists <local/signal-desktop>
          }
        '';
      };

      "signal-desktop-chrome-sandbox" = {
        state = cfg.desktop.chat.signal-desktop.mode;
        profile = ''
          abi <abi/4.0>,
          include <tunables/global>

          profile signal-desktop-chrome-sandbox ${pkgs.electron_43}/libexec/electron/chrome-sandbox {
            include <abstractions/base>
            include <abstractions/curios/gconv>

            # NixOS shared libraries (see abstractions/electron for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                    mr,

            capability setgid,
            capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability dac_override,

            ${pkgs.electron_43}/libexec/electron/chrome-sandbox                mr,
            ${pkgs.electron_43}/libexec/electron/electron                      rPx -> signal-desktop,

            @{PROC}                                                            r,
            @{PROC}/@{pids}/                                                   r,
            owner @{PROC}/@{pid}/fd/                                           r,
            owner @{PROC}/@{pid}/oom_adj                                       rw,
            owner @{PROC}/@{pid}/oom_score_adj                                 rw,

            # Silencer
            deny /dev/pts/@{u16} rw,

            include if exists <local/signal-desktop-chrome-sandbox>
          }
        '';
      };

      "discord" = {
        state = cfg.desktop.chat.discord.mode;
        profile = let
          modeFlag = if cfg.desktop.chat.discord.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{lib_dirs} = ${pkgs.discord}/opt/Discord
          @{config_dirs} = @{HOME}/.config/discord
          @{cache_dirs} = @{HOME}/.cache/discord

          profile discord ${pkgs.discord}/opt/Discord/Discord ${modeFlag} {
            include <abstractions/chromium>
            include <abstractions/curios/secrets-deny-browsers>

            # Discord wrapper script (created by wrapProgramShell).
            # The real Electron binary is moved to .Discord-wrapped; the
            # wrapper sets up env vars, runs stageModules and
            # disableBreakingUpdates.py, then execs .Discord-wrapped.
            @{lib_dirs}/Discord                                                mrix,
            @{lib_dirs}/.Discord-wrapped                                       mrix,

            # Chrome sandbox (child profile)
            @{lib_dirs}/chrome-sandbox                                         rPx -> discord-sandbox,

            # Chrome crashpad handler
            @{lib_dirs}/chrome_crashpad_handler                                rix,

            # Discord native modules (libuv-worker needs mmap for .node and .so files,
            # gpu_encoder_helper needs exec for hardware video encoding)
            @{lib_dirs}/modules/**                                             mr,
            @{lib_dirs}/modules/discord_voice/gpu_encoder_helper               rix,

            # /etc directory listing (libuv-worker)
            /etc/                                                              r,

            # Shell for the wrapper script shebang and stageModules
            /nix/store/*-discord-stage-modules                                 rix,

            # disableBreakingUpdates.py (run directly by wrapper, shebang → python3)
            ${pkgs.discord.disableBreakingUpdates}/bin/disable-breaking-updates.py  rix,
            ${pkgs.python3}/bin/python3                                        rix,
            ${pkgs.python3}/lib/**                                             r,

            # Discord IPC socket
            owner @{run}/user/@{uid}/discord-ipc-@{int}                        rw,

            # Discord crash dumps and temp files
            owner /tmp/Discord\ Crashes/                                       rw,
            owner /tmp/Discord\ Crashes/**                                     rw,
            owner /tmp/discord.sock                                            rw,
            owner /tmp/net-export/                                             rw,
            owner /tmp/net-export/**                                           rw,

            # Discord process management reads other PIDs' cmdline (Utils thread)
            @{PROC}/@{pid}/cmdline                                             r,

            # Silencer
            deny ptrace read,

            # Flatpak app exports (xdg-open resolving links to installed Flatpak apps)
            /var/lib/flatpak/app/                                              r,
            /var/lib/flatpak/app/**                                            r,

            include if exists <local/discord>
          }
        '';
      };

      "discord-sandbox" = {
        state = cfg.desktop.chat.discord.mode;
        profile = ''
          abi <abi/4.0>,
          include <tunables/global>

          profile discord-sandbox ${pkgs.discord}/opt/Discord/chrome-sandbox {
            include <abstractions/base>

            #capability setgid,
            #capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability sys_resource,

            ${pkgs.discord}/opt/Discord/chrome-sandbox      mr,
            ${pkgs.discord}/opt/Discord/Discord             rPx -> discord,

            @{PROC}/@{pids}/                                r,
            owner @{PROC}/@{pid}/fd/                        r,
            owner @{PROC}/@{pid}/oom_adj                    rw,
            owner @{PROC}/@{pid}/oom_score_adj              rw,

            include if exists <local/discord-sandbox>
          }
        '';
      };

      "evince" = {
        state = cfg.desktop.office.evince.mode;
        profile = let
          modeFlag = if cfg.desktop.office.evince.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          profile evince ${pkgs.evince}/bin/evince ${modeFlag} {
            include <abstractions/curios/evince>

            deny network inet,
            deny network inet6,

            ${pkgs.evince}/bin/evince                                          rix,
            ${pkgs.evince}/bin/.evince-wrapped                                 rix,
            ${pkgs.evince}/bin/evince-previewer                                rPx -> evince-previewer,
            ${pkgs.evince}/libexec/evinced                                     rPx -> evinced,
            ${pkgs.brave}/bin/brave                                            rPx -> brave-wrapper,
            ${pkgs.xdg-utils}/bin/xdg-open                                     rix,
            /run/current-system/sw/bin/xdg-open                                rix,
            ${pkgs.cosmic-files}/bin/cosmic-files                              rUx,
            /run/current-system/sw/bin/cosmic-files                            rUx,

            owner @{HOME}/[^.]*/                                               rwk,
            owner @{HOME}/[^.]*/**                                             rwkm,
            /run/media/**                                                      rw,
            owner /tmp/.goutputstream-*                                        rw,
            owner /tmp/*.pdf                                                   r,
            owner /tmp/evince-@{int}/                                          rwk,
            owner /tmp/evince-@{int}/**                                        rw,
            owner /tmp/gtkprint_@{rand6}                                       rw,
            owner /tmp/gtkprint@{rand6}                                        rw,
            owner /tmp/org.gnome.Evince-@{int}/                                rwk,
            owner /tmp/org.gnome.Evince-@{int}/**                              rw,

            include if exists <local/evince>
          }
        '';
      };

      "evince-previewer" = {
        state = cfg.desktop.office.evince.mode;
        profile = let
          modeFlag = if cfg.desktop.office.evince.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          profile evince-previewer ${pkgs.evince}/bin/evince-previewer ${modeFlag} {
            include <abstractions/curios/evince>

            deny network inet,
            deny network inet6,

            ${pkgs.evince}/bin/evince-previewer                                rix,
            ${pkgs.evince}/bin/.evince-previewer-wrapped                       rix,

            owner @{HOME}/[^.]*/                                               rwk,
            owner @{HOME}/[^.]*/**                                             rwkm,
            owner /tmp/.goutputstream-*                                        rw,
            owner /tmp/gtkprint_@{rand6}                                       rw,
            owner /tmp/gtkprint@{rand6}                                        rw,

            include if exists <local/evince-previewer>
          }
        '';
      };

      "evinced" = {
        state = cfg.desktop.office.evince.mode;
        profile = let
          modeFlag = if cfg.desktop.office.evince.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          profile evinced ${pkgs.evince}/libexec/evinced ${modeFlag} {
            include <abstractions/curios/evince>

            deny network inet,
            deny network inet6,

            ${pkgs.evince}/libexec/evinced                                     rix,
            ${pkgs.evince}/libexec/.evinced-wrapped                            rix,
            ${pkgs.evince}/bin/evince                                          rPx -> evince,

            include if exists <local/evinced>
          }
        '';
      };

      "evince-thumbnailer" = {
        state = cfg.desktop.office.evince.mode;
        profile = let
          modeFlag = if cfg.desktop.office.evince.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          profile evince-thumbnailer ${pkgs.evince}/bin/evince-thumbnailer ${modeFlag} {
            include <abstractions/curios/evince>

            deny network inet,
            deny network inet6,

            ${pkgs.evince}/bin/evince-thumbnailer                              rix,
            ${pkgs.evince}/bin/.evince-thumbnailer-wrapped                     rix,

            owner @{HOME}/[^.]*/**                                             r,
            /run/media/**                                                      r,
            owner @{HOME}/.cache/thumbnails/                                   rwk,
            owner @{HOME}/.cache/thumbnails/**                                 rwk,
            owner /tmp/gnome-desktop-file-to-thumbnail.pdf                     r,
            owner /tmp/gnome-desktop-thumbnailer.png                           w,
            owner /tmp/.gnome_desktop_thumbnail*                               w,
            owner /tmp/gnome-desktop-*                                         rw,
            owner /tmp/evince-thumbnailer*/                                    rwk,
            owner /tmp/evince-thumbnailer*/**                                  rw,

            deny @{HOME}/.local/share/gvfs-metadata/*                          r,

            include if exists <local/evince-thumbnailer>
          }
        '';
      };

      "onlyoffice-desktopeditors" = {
        state = cfg.desktop.office.onlyoffice.mode;
        profile = let
          modeFlag = if cfg.desktop.office.onlyoffice.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          @{config_dirs} = @{HOME}/.config/onlyoffice
          @{cache_dirs} = @{HOME}/.cache/onlyoffice
          @{lib_dirs} = ${pkgs.onlyoffice-desktopeditors.fhsenv}

          profile onlyoffice-desktopeditors ${pkgs.onlyoffice-desktopeditors}/bin/onlyoffice-desktopeditors ${modeFlag} {
            include <abstractions/curios/graphics>
            include <abstractions/curios/fhsenv-bwrap>
            include <abstractions/curios/secrets-deny>
            include <abstractions/curios/secrets-deny-browsers>

            # OnlyOffice bwrap entry + real init (app-specific; not on passthru)
            ${pkgs.onlyoffice-desktopeditors}/bin/onlyoffice-desktopeditors          rix,
            /nix/store/*-onlyoffice-desktopeditors-*-init                            rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/.onlyoffice-desktopeditors-wrapped rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/desktopeditors                     rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/DesktopEditors                     rix,
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/DesktopEditors    rix,
            @{lib_dirs}/opt/onlyoffice/desktopeditors/DesktopEditors                 rix,

            # OnlyOffice binary package (plugins, Qt libs, CEF, converter)
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/**             mr,
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/converter/x2t  rix,
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/editors_helper rix,

            # curl used by wrapper / network helpers
            ${pkgs.curl}/bin/curl                                              rix,

            # Network
            network inet dgram,
            network inet6 dgram,
            network inet stream,
            network inet6 stream,
            network netlink raw,

            # User config and cache
            owner @{config_dirs}/                                              rwk,
            owner @{config_dirs}/**                                            rwkm,
            owner @{cache_dirs}/                                               rwk,
            owner @{cache_dirs}/**                                             rwkm,

            # Flatpak-exported icons/themes/applications
            /var/lib/flatpak/exports/share/icons/                              r,
            /var/lib/flatpak/exports/share/icons/**                            r,
            /var/lib/flatpak/exports/share/themes/                             r,
            /var/lib/flatpak/exports/share/themes/**                           r,
            /var/lib/flatpak/exports/share/applications/                       r,
            /var/lib/flatpak/exports/share/applications/**                     r,

            include if exists <local/onlyoffice-desktopeditors>
          }
        '';
      };

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
