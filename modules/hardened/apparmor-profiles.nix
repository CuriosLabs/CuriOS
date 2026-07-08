# CuriOS NixOS-path AppArmor profiles.
# See pkgs.apparmor-profiles and security.apparmor options.
# `nixos-option security.lsm`, `aa-enabled`, `sudo aa-status`
# `eza -l -tree /etc/apparmor.d/`
# Useful commands:
# `sudo aa-status` `sudo aa-status --complaining`
# sudo grep "apparmor=\"DENIED\"" /var/log/audit/audit.log | grep -i brave
# sudo grep -E "apparmor=\"(ALLOWED|DENIED)\"" /var/log/audit/audit.log | grep -i onlyoffice > /tmp/onlyoffice-audit.log
# Clear AppArmor change when debugging:
# `sudo fd -d 1 . /var/cache/apparmor/ -E logprof -x rm -rf {} && sudo systemctl restart apparmor`
#
# TODO: Add AppArmor profiles in priority order:
#   Tier 1 — Chromium/Electron (render untrusted network content):
#     - cursor (Electron IDE)
#   Tier 1 — Document viewers (PDF is turing-complete: JS, fonts, 3D;
#            long CVE history; files arrive from email/web):
#     - evince / okular / zathura (PDF viewers)
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

      office = {
        onlyoffice = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            # TODO: more OnlyOffice testing before changing default mode to enforce
            default = "complain";
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
        # runtime and user dconf paths (used by COSMIC
        # and other desktop environments) must be allowed here.
        owner @{run}/user/@{uid}/dconf/cosmic  rwk,
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
        include <abstractions/dri-common>
        # DRI / GPU access
        # udmabuf (GPU buffer sharing for zero-copy video/camera)
        /dev/udmabuf                                                  rw,
        /dev/shm/                                                     r,
        # GPU shader caches (Mesa OpenGL + RADV Vulkan)
        owner @{HOME}/.cache/mesa_shader_cache/**                     rwk,
        owner @{HOME}/.cache/radv_builtin_shaders/**                  rwk,
        # Vulkan ICD/loader config (user-installed implicit layers)
        owner @{HOME}/.local/share/vulkan/implicit_layer.d/{,*.json}  r,
      '';

      "abstractions/curios/nss" = ''
        abi <abi/4.0>,
        # NSS certificate database (client certificates, CA trust)
        owner @{HOME}/.pki/nssdb/                        rw,
        owner @{HOME}/.pki/nssdb/pkcs11.txt              rw,
        owner @{HOME}/.pki/nssdb/{cert9,key4}.db         rwk,
        owner @{HOME}/.pki/nssdb/{cert9,key4}.db-journal rw,
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
        include <abstractions/fonts>
        include <abstractions/dconf>
        include <abstractions/ssl_certs>
        include <abstractions/curios/devices>
        include <abstractions/curios/gconv>
        include <abstractions/curios/graphics>
        include <abstractions/curios/nss>
        include <abstractions/curios/wayland>

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
        # Downloads directory (Chromium temp download files: .crdownload,
        # .org.chromium.Chromium.* temp files during download).
        # AppArmor can't read XDG config at policy load time, so we allow
        # write/create in any top-level home directory.
        owner @{HOME}/*/                                                       rwk,
        owner @{HOME}/*/**                                                     rwkm,
        owner @{HOME}/*/.org.chromium.Chromium.*                               rwkm,
        owner @{HOME}/*.crdownload                                             rwkm,
        # XDG MIME associations and application listings
        owner @{HOME}/.config/mimeapps.list                                    r,
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

        # Silencer
        deny /etc/opt/                                                         w,
        deny @{HOME}/.local/share/gvfs-metadata/*                              r,
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
        /nix/store/*-electron-*/bin/electron                                       rix,
        /nix/store/*-electron-unwrapped-*/libexec/electron/electron                mrix,
        /nix/store/*-electron-unwrapped-*/libexec/electron/chrome_crashpad_handler rix,

        # Electron libraries and resources
        /nix/store/*-electron-unwrapped-*/libexec/electron/*.so*                   mr,
        /nix/store/*-electron-unwrapped-*/libexec/electron/*.pak                   r,
        /nix/store/*-electron-unwrapped-*/libexec/electron/*.dat                   r,
        /nix/store/*-electron-unwrapped-*/libexec/electron/*.bin                   r,
        /nix/store/*-electron-unwrapped-*/libexec/electron/locales/**              r,
        /nix/store/*-electron-unwrapped-*/libexec/electron/resources/**            r,
        /nix/store/*-electron-unwrapped-*/libexec/electron/vk_swiftshader_icd.json r,

        # PipeWire
        owner @{run}/user/*/pipewire-*                                             rw,
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

            # Signal Desktop wrapper (inherits profile through electron exec chain)
            ${pkgs.signal-desktop}/bin/signal-desktop                        rix,

            # Chromium sandbox (separate profile with elevated capabilities)
            ${pkgs.electron_42}/libexec/electron/chrome-sandbox                     rPx -> signal-desktop-chrome-sandbox,

            # Signal Desktop app resources
            ${pkgs.signal-desktop}/share/signal-desktop/**                   r,
            ${pkgs.signal-desktop}/share/signal-desktop/app.asar             mr,
            # Native node modules (libsignal crypto, ringrtc WebRTC) — need mmap
            ${pkgs.signal-desktop}/share/signal-desktop/app.asar.unpacked/**/*.node mr,

            # Signal Desktop flags
            owner @{HOME}/.config/signal-desktop-flags.conf                         r,

            # Temporary files
            /tmp/signal-desktop-*/**                                                rw,

            # Bluetooth observe (for nearby device discovery)
            @{sys}/class/bluetooth/                                                 r,
            @{run}/bluetooth/**                                                     r,

            include if exists <local/signal-desktop>
          }
        '';
      };

      "signal-desktop-chrome-sandbox" = {
        state = cfg.desktop.chat.signal-desktop.mode;
        profile = ''
          abi <abi/4.0>,
          include <tunables/global>

          profile signal-desktop-chrome-sandbox ${pkgs.electron_42}/libexec/electron/chrome-sandbox {
            include <abstractions/base>
            include <abstractions/curios/gconv>

            # NixOS shared libraries (see abstractions/electron for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                         mr,

            capability setgid,
            capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability dac_override,

            ${pkgs.electron_42}/libexec/electron/chrome-sandbox                     mr,
            ${pkgs.electron_42}/libexec/electron/electron                           rPx -> signal-desktop,

            @{PROC}                                                                 r,
            @{PROC}/@{pids}/                                                        r,
            owner @{PROC}/@{pid}/fd/                                                r,
            owner @{PROC}/@{pid}/oom_adj                                            rw,
            owner @{PROC}/@{pid}/oom_score_adj                                      rw,

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
            /nix/store/*-disable-breaking-updates.py/bin/disable-breaking-updates.py   rix,
            /nix/store/*-python3-*/bin/python3                                         rix,
            /nix/store/*-python3-*/lib/**                                              r,

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
            include <abstractions/base>
            include <abstractions/nameservice>
            include <abstractions/consoles>
            include <abstractions/fonts>
            include <abstractions/dconf>
            include <abstractions/ssl_certs>
            include <abstractions/curios/devices>
            include <abstractions/curios/gconv>
            include <abstractions/curios/graphics>

            # Bubblewrap entry script and executor (link chain: bin -> -bwrap)
            ${pkgs.onlyoffice-desktopeditors}/bin/onlyoffice-desktopeditors                  rix,
            /nix/store/*-container-init                                                      rix,
            ${pkgs.glibc.bin}/bin/ldconfig                                                      rix,
            /nix/store/*-onlyoffice-desktopeditors-*-init                                    rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/.onlyoffice-desktopeditors-wrapped   rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/onlyoffice-desktopeditors            rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/desktopeditors                       rix,
            ${pkgs.onlyoffice-desktopeditors}/bin/DesktopEditors                       rix,
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/DesktopEditors      rix,

            # Shell and coreutils (bwrap script, init, ldconfig helpers)
            ${pkgs.bashInteractive}/bin/sh                                     rix,
            ${pkgs.bashInteractive}/bin/bash                                   rix,
            ${pkgs.coreutils-full}/bin/*                                       rix,
            ${pkgs.coreutils}/bin/*                                            rix,
            ${pkgs.curl}/bin/curl                                              rix,

            # Bubblewrap binary
            ${pkgs.bubblewrap}/bin/bwrap                                       rix,

            # FHSEnv rootfs (OnlyOffice binaries and libs inside FHS namespace)
            @{lib_dirs}/                                                       r,
            @{lib_dirs}/**                                                     mr,
            @{lib_dirs}/opt/onlyoffice/desktopeditors/DesktopEditors           rix,

            # OnlyOffice binary package (plugins, Qt libs, CEF, converter)
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/**          mr,
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/converter/x2t  rix,

            # Nix store shared libraries (mmap needed by bwrap and child processes)
            /nix/store/**                                                      r,
            /nix/store/*/lib{,32,64}/**.so*                                    mr,
            ${pkgs.onlyoffice-desktopeditors}/share/desktopeditors/editors_helper rix,

            # Root filesystem — bwrap sets up the sandbox namespace via mount,
            # mkdir, symlink, and mknod under /newroot/, /oldroot/ and /tmp/.
            /                                                                  r,
            owner /**                                                          rwk,

            # Mount, pivot_root, unmount (bwrap namespace bootstrap)
            mount,
            umount,
            pivot_root,

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

            # Proc (uid_map, gid_map, setgroups, mountinfo, fd/ for bwrap)
            @{PROC}/                                                           r,
            owner @{PROC}/@{pid}/fd/                                           r,
            owner @{PROC}/@{pid}/fd/@{int}                                     w,
            owner @{PROC}/@{pid}/uid_map                                       rw,
            owner @{PROC}/@{pid}/gid_map                                       rw,
            owner @{PROC}/@{pid}/setgroups                                     rw,
            owner @{PROC}/@{pid}/mountinfo                                     r,
            @{PROC}/@{pid}/stat                                                r,
            @{PROC}/sys/kernel/overflow{uid,gid}                               r,
            @{PROC}/sys/fs/inotify/max_user_watches                            r,

            # Flatpak-exported icons/themes/applications
            /var/lib/flatpak/exports/share/icons/                              r,
            /var/lib/flatpak/exports/share/icons/**                            r,
            /var/lib/flatpak/exports/share/themes/                             r,
            /var/lib/flatpak/exports/share/themes/**                           r,
            /var/lib/flatpak/exports/share/applications/                       r,
            /var/lib/flatpak/exports/share/applications/**                     r,

            # User namespace + bwrap + container-init capabilities
            userns,
            capability setpcap,
            capability sys_admin,
            capability sys_chroot,
            capability sys_ptrace,
            capability mknod,

            # FHS namespace paths (bind-mounted from nix store, root-owned)
            /usr/**                                                            r,

            # .host-etc (host /etc bind-mounted into bwrap namespace, root-owned)
            /.host-etc/**                                                      r,

            # Host resolv.conf (bind-mounted into FHS namespace via .host-etc)
            /etc/resolv.conf                                                   r,

            include if exists <local/onlyoffice-desktopeditors>
          }
        '';
      };
    };
  };
}
