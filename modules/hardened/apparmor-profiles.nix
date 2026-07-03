# CuriOS NixOS-path AppArmor profiles.
# See pkgs.apparmor-profiles and security.apparmor options.
# `nixos-option security.lsm`, `aa-enabled`, `sudo aa-status`
# `eza -l -tree /etc/apparmor.d/`
# Useful commands:
# `sudo aa-status` `sudo aa-status --complaining`
# `sudo ausearch -m AVC -ts today -c brave 2>/dev/nulla-i || sudo grep "apparmor=\"DENIED\"" /var/log/audit/audit.log | grep -i brave`
# A shared `abstractions/electron` include is provided for Electron-based apps.
# It encapsulates the common NixOS Electron runtime rules (shared binary chain,
# /proc sandbox access, DRI/GPU, display, D-Bus, audio, etc.). App profiles need
# only set @{config_dirs} and @{cache_dirs} variables, add app-specific paths,
# then `include <abstractions/electron>`.
#
# Profile priority is driven by "parses untrusted complex input", not just by
# being Electron. Chromium/Electron apps are top-tier (render arbitrary network
# content, huge attack surface, bundled Chromium often behind Chrome stable,
# hold credentials/sessions + network + filesystem + camera/mic), but several
# other categories are equally deserving and frequently neglected on desktop
# Linux:
#
# TODO: Add AppArmor profiles in priority order:
#   Tier 1 — Chromium/Electron (render untrusted network content):
#     - signal-desktop (Electron messenger)                       [DONE]
#     - cursor (Electron IDE)
#     - onlyoffice-desktopeditors (CEF-based office suite)
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

{ config, lib, ... }:

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
            default = "complain";
            description = "AppArmor profile mode for Brave.";
          };
        };
      };

      chat = {
        signal-desktop = {
          mode = mkOption {
            type = types.enum [ "complain" "enforce" "disable" ];
            default = "complain";
            description = "AppArmor profile mode for Signal Desktop.";
          };
        };
      };
    };
  };

  config = mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.includes = {
      "abstractions/electron" = ''
        # CuriOS common abstraction for Electron-based applications on NixOS.
        # The Electron runtime is shared across all Electron apps via
        # /nix/store/*-electron-unwrapped-* — only the app.asar/resources differ.
        #
        # REQUIRED VARIABLES (define in the calling profile header, before this include):
        #   @{config_dirs}  — app config directory  (e.g. @{HOME}/.config/Signal)
        #   @{cache_dirs}   — app cache directory   (e.g. @{HOME}/.cache/signal-desktop)

        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/fonts>
        include <abstractions/dconf>
        include <abstractions/ssl_certs>

        # NixOS shared libraries. Upstream abstractions/base only grants
        # access to FHS paths (/{usr/,}lib{,32,64}/*.so*); on NixOS every
        # library — including glibc (libdl.so.2, libc.so.6, ld-linux) —
        # lives in /nix/store and must be allowed explicitly. Without this
        # the dynamic loader aborts on the first exec with:
        #   "error while loading shared libraries: libdl.so.2: cannot open
        #    shared object file: No such file or directory"
        # Recursive to cover DRI drivers (lib/dri/), NSS modules, etc.
        # The nix store is world-readable by design, so this is not a
        # meaningful security boundary on NixOS.
        /nix/store/*/lib{,32,64}/**.so*                                          mr,

        # glibc charset conversion (gconv-modules is a text file, not .so)
        /nix/store/*/lib{,32,64}/gconv/**                                        mr,

        # Chromium sandbox. On NixOS the nix store is read-only so
        # chrome-sandbox cannot be SUID 4755. Chromium must use unprivileged
        # user namespaces instead. `userns` allows unshare(CLONE_NEWUSER);
        # `capability sys_admin` is required for subsequent PID/network
        # namespace creation within the user namespace sandbox;
        # `capability sys_chroot` is required by the zygote process to
        # chroot sandboxed children into their namespace.
        # sys_ptrace: Chromium crash handler inspects child processes.
        userns,
        capability sys_admin,
        capability sys_chroot,
        capability sys_ptrace,

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

        # Shell and utilities for NixOS wrapper scripts
        /nix/store/*/bin/{sh,bash,dash}                                            rix,
        /nix/store/*coreutils*/bin/*                                               rix,

        # Network access
        network inet dgram,
        network inet6 dgram,
        network inet stream,
        network inet6 stream,
        network netlink raw,

        # User config and cache (uses variables from calling profile)
        owner @{config_dirs}/**                                                    rwk,
        owner @{cache_dirs}/**                                                     rwk,

        # Temporary files. Chromium creates shared-memory files and dirs
        # in /tmp/.org.chromium.Chromium.* — 'rwk' on the file pattern allows
        # mknod+read of top-level files, 'wk' on */ allows mkdir of dirs,
        # 'rwkm' on /** covers contents.
        owner /tmp/.org.chromium.Chromium.*                                        rwk,
        owner /tmp/.org.chromium.Chromium.*/                                       wk,
        owner /tmp/.org.chromium.Chromium.*/**                                     rwkm,
        # Chromium scoped temp dirs (file picker, downloads, plugins).
        owner /tmp/scoped_dir*/                                                    rwk,
        owner /tmp/scoped_dir*/**                                                  rwkm,
        owner @{HOME}/.tmp/**                                                      rw,

        # /proc access for Chromium sandbox
        owner @{PROC}/@{pid}/fd/                                                  r,
        owner @{PROC}/@{pid}/fd/@{int}                                            w,
        owner @{PROC}/@{pid}/maps                                                 r,
        owner @{PROC}/@{pid}/stat                                                 r,
        owner @{PROC}/@{pid}/status                                               r,
        owner @{PROC}/@{pid}/task/                                                r,
        owner @{PROC}/@{pid}/task/@{tid}/comm                                     rw,
        owner @{PROC}/@{pid}/cmdline                                              r,
        owner @{PROC}/@{pid}/environ                                              r,
        owner @{PROC}/@{pid}/oom_adj                                              r,
        owner @{PROC}/@{pid}/oom_score_adj                                        rw,
        owner @{PROC}/@{pid}/cgroup                                               r,
        owner @{PROC}/@{pid}/mounts                                               r,
        owner @{PROC}/@{pid}/mountinfo                                            r,
        owner @{PROC}/@{pid}/smaps_rollup                                         r,
        owner @{PROC}/@{pid}/limits                                               r,
        @{PROC}/                                                                  r,
        @{PROC}/sys/kernel/yama/ptrace_scope                                      r,

        # Chromium processes read each other's proc info (parent reads
        # child stats, ThreadPool reads sibling thread status). These must
        # be non-owner since the reading process differs from the target.
        @{PROC}/@{pid}/stat                                                        r,
        @{PROC}/@{pid}/task/@{tid}/status                                          r,
        @{PROC}/@{pid}/comm                                                        r,
        @{PROC}/@{pid}/statm                                                       r,

        # User namespace setup. On NixOS the nix store is read-only so
        # chrome-sandbox cannot be SUID 4755. Chromium must use unprivileged
        # user namespaces instead, which requires writing uid/gid mappings.
        owner @{PROC}/@{pid}/uid_map                                              rw,
        owner @{PROC}/@{pid}/gid_map                                              rw,
        owner @{PROC}/@{pid}/setgroups                                            rw,

        # inotify limits (Chromium file watcher)
        @{PROC}/sys/fs/inotify/max_user_watches                                   r,
        @{PROC}/sys/fs/inotify/max_queued_events                                  r,
        @{PROC}/sys/fs/inotify/max_user_instances                                 r,

        # DRI / GPU access
        /dev/                                                                     r,
        /dev/dri/                                                                 r,
        /dev/dri/**                                                               rw,
        /dev/shm/                                                                 r,
        /dev/shm/**                                                               rw,
        # udmabuf (GPU buffer sharing for zero-copy video/camera)
        /dev/udmabuf                                                              rw,

        # GPU shader caches (Mesa OpenGL + RADV Vulkan)
        owner @{HOME}/.cache/mesa_shader_cache/**                                 rwk,
        owner @{HOME}/.cache/radv_builtin_shaders/**                              rwk,

        # Vulkan ICD/loader config (user-installed implicit layers)
        owner @{HOME}/.local/share/vulkan/**                                      r,

        # Wayland / X11
        owner @{run}/user/@{uid}/wayland-*                                        rw,
        /tmp/.X11-unix/X*                                                         rw,

        # D-Bus
        owner @{run}/user/@{uid}/bus                                              rw,

        # dconf (user settings). The NixOS abstractions/dconf include only
        # covers /etc/dconf/**; runtime and user dconf paths (used by COSMIC
        # and other desktop environments) must be allowed here.
        owner @{run}/user/@{uid}/dconf/**                                         rwk,
        owner @{HOME}/.config/dconf/**                                            r,

        # PipeWire / PulseAudio
        owner @{run}/user/@{uid}/pipewire-*                                       rw,
        @{run}/user/@{uid}/pulse/                                                 r,
        @{run}/user/@{uid}/pulse/**                                               rw,
        # PulseAudio cookie (audio authentication)
        owner @{HOME}/.config/pulse/                                              r,
        owner @{HOME}/.config/pulse/cookie                                        rwk,
        owner @{HOME}/.pulse-cookie                                               r,

        # cgroup CPU limits (Chromium resource monitoring)
        @{sys}/fs/cgroup/**                                                       r,

        # GTK
        owner @{HOME}/.config/gtk-3.0/**                                          r,
        owner @{HOME}/.config/gtk-4.0/**                                          r,

        # XDG user directories (used by file dialogs, download paths)
        owner @{HOME}/.config/user-dirs.dirs                                      r,
        # XDG MIME associations and application listings
        owner @{HOME}/.config/mimeapps.list                                       r,
        owner @{HOME}/.local/share/applications/                                  r,
        owner @{HOME}/.local/share/applications/**                                r,

        # NixOS shared resources. On NixOS fonts, gsettings schemas, icon
        # themes, translations, xkb config, fontconfig caches, GDK pixbuf
        # loaders etc. live in /nix/store/ rather than /usr/share/ and
        # /etc/fonts/. Upstream abstractions only cover FHS paths.
        # The nix store is world-readable by design, so granting read
        # access to it is not a meaningful security boundary on NixOS —
        # equivalent to /usr/share/** r on FHS distros. AppArmor's value
        # here is in restricting writes, network, capabilities, and user
        # data access, not reads of world-readable system files.
        /nix/store/**                                                              r,

        # Icons, themes, shared data
        @{HOME}/.local/share/icons/**                                             r,
        @{HOME}/.local/share/themes/**                                            r,
        @{HOME}/.local/share/mime/**                                              r,
        # Flatpak-exported icons/themes/applications
        /var/lib/flatpak/exports/share/icons/**                                   r,
        /var/lib/flatpak/exports/share/themes/**                                  r,
        /var/lib/flatpak/exports/share/applications/                              r,
        /var/lib/flatpak/exports/share/applications/**                            r,

        # System config
        /etc/machine-id                                                           r,
        @{sys}/devices/system/cpu/**                                              r,

        # Hardware detection (GPU/PCI enumeration, active tty)
        @{sys}/bus/pci/devices/                                                   r,
        @{sys}/devices/pci*/**                                                    r,
        @{sys}/devices/virtual/tty/tty0/active                                    r,

        # Device access
        /dev/urandom                                                              r,
        /dev/random                                                               r,
        /dev/null                                                                 rw,
        /dev/zero                                                                 rw,
        /dev/log                                                                  w,
        # Terminal access (Chromium crash reporting, terminal detection)
        /dev/tty                                                                  rw,
        /dev/pts/@{int}                                                           rw,

        # Silencer
        deny /etc/opt/                                                            w,
        deny @{HOME}/.local/share/gvfs-metadata/*                                r,
      '';

      "abstractions/chromium" = ''
        # CuriOS common abstraction for Chromium-based browsers on NixOS.
        # Inspired by https://github.com/roddhjav/apparmor.d/blob/main/apparmor.d/abstractions/app/chromium
        #
        # This abstraction is the browser counterpart to abstractions/electron:
        # electron covers apps that bundle the Electron runtime, while this
        # covers apps that ship their own Chromium (Brave, Chromium, etc.).
        # Both share the same NixOS-specific rules (nix-store shared libraries,
        # Chromium sandbox /proc access, DRI, D-Bus, PipeWire, etc.).
        #
        # REQUIRED VARIABLES (define in the calling profile header, before this include):
        #   @{lib_dirs}    — browser library/binary directory
        #                    (e.g. /nix/store/*-brave*/opt/brave.com/brave)
        #   @{config_dirs} — user config directory (e.g. @{HOME}/.config/BraveSoftware)
        #   @{cache_dirs}  — user cache directory  (e.g. @{HOME}/.cache/BraveSoftware)

        include <abstractions/base>
        include <abstractions/nameservice>
        include <abstractions/fonts>
        include <abstractions/dconf>
        include <abstractions/ssl_certs>

        # NixOS shared libraries. Upstream abstractions/base only grants
        # access to FHS paths (/{usr/,}lib{,32,64}/*.so*); on NixOS every
        # library — including glibc (libdl.so.2, libc.so.6, ld-linux) —
        # lives in /nix/store and must be allowed explicitly. Without this
        # the dynamic loader aborts on the first exec with:
        #   "error while loading shared libraries: libdl.so.2: cannot open
        #    shared object file: No such file or directory"
        # Recursive to cover DRI drivers (lib/dri/), NSS modules, etc.
        # The nix store is world-readable by design, so this is not a
        # meaningful security boundary on NixOS.
        /nix/store/*/lib{,32,64}/**.so*                                          mr,

        # glibc charset conversion (gconv-modules is a text file, not .so)
        /nix/store/*/lib{,32,64}/gconv/**                                        mr,

        # Chromium sandbox. On NixOS the nix store is read-only so
        # chrome-sandbox cannot be SUID 4755. Chromium must use unprivileged
        # user namespaces instead. `userns` allows unshare(CLONE_NEWUSER);
        # `capability sys_admin` is required for subsequent PID/network
        # namespace creation within the user namespace sandbox;
        # `capability sys_chroot` is required by the zygote process to
        # chroot sandboxed children into their namespace.
        # sys_ptrace: Chromium crash handler inspects child processes.
        userns,
        capability sys_admin,
        capability sys_chroot,
        capability sys_ptrace,

        # Browser libraries, resources, and Widevine DRM
        @{lib_dirs}/{,**}                                                         r,
        @{lib_dirs}/*.so*                                                         mr,
        @{lib_dirs}/WidevineCdm/**                                                mrwk,

        # Network access
        network inet dgram,
        network inet6 dgram,
        network inet stream,
        network inet6 stream,
        network netlink raw,

        # User config and cache (uses variables from calling profile)
        owner @{config_dirs}/**                                                   rwk,
        owner @{cache_dirs}/**                                                    rwk,

        # Temporary files. Chromium creates shared-memory files and dirs
        # in /tmp/.org.chromium.Chromium.* — 'rwk' on the file pattern allows
        # mknod+read of top-level files, 'wk' on */ allows mkdir of dirs,
        # 'rwkm' on /** covers contents.
        owner /tmp/.org.chromium.Chromium.*                                       rwk,
        owner /tmp/.org.chromium.Chromium.*/                                      wk,
        owner /tmp/.org.chromium.Chromium.*/**                                    rwkm,
        # Chromium scoped temp dirs (file picker, downloads, plugins).
        owner /tmp/scoped_dir*/                                                   rwk,
        owner /tmp/scoped_dir*/**                                                 rwkm,
        owner @{HOME}/.tmp/**                                                     rw,

        # /proc access for Chromium sandbox
        owner @{PROC}/@{pid}/fd/                                                  r,
        owner @{PROC}/@{pid}/fd/@{int}                                            w,
        owner @{PROC}/@{pid}/maps                                                 r,
        owner @{PROC}/@{pid}/stat                                                 r,
        owner @{PROC}/@{pid}/status                                               r,
        owner @{PROC}/@{pid}/task/                                                r,
        owner @{PROC}/@{pid}/task/@{tid}/comm                                     rw,
        owner @{PROC}/@{pid}/cmdline                                              r,
        owner @{PROC}/@{pid}/environ                                              r,
        owner @{PROC}/@{pid}/oom_adj                                              r,
        owner @{PROC}/@{pid}/oom_score_adj                                        rw,
        owner @{PROC}/@{pid}/cgroup                                               r,
        owner @{PROC}/@{pid}/mounts                                               r,
        owner @{PROC}/@{pid}/mountinfo                                            r,
        owner @{PROC}/@{pid}/smaps_rollup                                         r,
        owner @{PROC}/@{pid}/limits                                               r,
        @{PROC}/                                                                  r,
        @{PROC}/sys/kernel/yama/ptrace_scope                                      r,

        # Chromium processes read each other's proc info (parent reads
        # child stats, ThreadPool reads sibling thread status). These must
        # be non-owner since the reading process differs from the target.
        @{PROC}/@{pid}/stat                                                       r,
        @{PROC}/@{pid}/task/@{tid}/status                                         r,
        @{PROC}/@{pid}/comm                                                       r,
        @{PROC}/@{pid}/statm                                                      r,

        # User namespace setup. On NixOS the nix store is read-only so
        # chrome-sandbox cannot be SUID 4755. Chromium must use unprivileged
        # user namespaces instead, which requires writing uid/gid mappings.
        owner @{PROC}/@{pid}/uid_map                                              rw,
        owner @{PROC}/@{pid}/gid_map                                              rw,
        owner @{PROC}/@{pid}/setgroups                                            rw,

        # inotify limits (Chromium file watcher)
        @{PROC}/sys/fs/inotify/max_user_watches                                   r,
        @{PROC}/sys/fs/inotify/max_queued_events                                  r,
        @{PROC}/sys/fs/inotify/max_user_instances                                 r,

        # DRI / GPU access
        /dev/                                                                     r,
        /dev/dri/                                                                 r,
        /dev/dri/**                                                               rw,
        /dev/shm/                                                                 r,
        /dev/shm/**                                                               rw,
        # udmabuf (GPU buffer sharing for zero-copy video/camera)
        /dev/udmabuf                                                              rw,

        # GPU shader caches (Mesa OpenGL + RADV Vulkan)
        owner @{HOME}/.cache/mesa_shader_cache/**                                 rwk,
        owner @{HOME}/.cache/radv_builtin_shaders/**                              rwk,

        # Vulkan ICD/loader config (user-installed implicit layers)
        owner @{HOME}/.local/share/vulkan/**                                      r,

        # Wayland / X11
        owner @{run}/user/@{uid}/wayland-*                                        rw,
        /tmp/.X11-unix/X*                                                         rw,

        # D-Bus
        owner @{run}/user/@{uid}/bus                                              rw,

        # dconf (user settings). The NixOS abstractions/dconf include only
        # covers /etc/dconf/**; runtime and user dconf paths (used by COSMIC
        # and other desktop environments) must be allowed here.
        owner @{run}/user/@{uid}/dconf/**                                         rwk,
        owner @{HOME}/.config/dconf/**                                            r,

        # PipeWire / PulseAudio
        owner @{run}/user/@{uid}/pipewire-*                                       rw,
        @{run}/user/@{uid}/pulse/                                                 r,
        @{run}/user/@{uid}/pulse/**                                               rw,
        # PulseAudio cookie (audio authentication)
        owner @{HOME}/.config/pulse/                                              r,
        owner @{HOME}/.config/pulse/cookie                                        rwk,
        owner @{HOME}/.pulse-cookie                                               r,

        # cgroup CPU limits (Chromium resource monitoring)
        @{sys}/fs/cgroup/**                                                       r,

        # GTK
        owner @{HOME}/.config/gtk-3.0/**                                          r,
        owner @{HOME}/.config/gtk-4.0/**                                          r,

        # XDG user directories (used by file dialogs, download paths)
        owner @{HOME}/.config/user-dirs.dirs                                      r,
        # XDG MIME associations and application listings
        owner @{HOME}/.config/mimeapps.list                                       r,
        owner @{HOME}/.local/share/applications/                                  r,
        owner @{HOME}/.local/share/applications/**                                r,

        # NixOS shared resources. On NixOS fonts, gsettings schemas, icon
        # themes, translations, xkb config, fontconfig caches, GDK pixbuf
        # loaders etc. live in /nix/store/ rather than /usr/share/ and
        # /etc/fonts/. Upstream abstractions only cover FHS paths.
        # The nix store is world-readable by design, so granting read
        # access to it is not a meaningful security boundary on NixOS —
        # equivalent to /usr/share/** r on FHS distros. AppArmor's value
        # here is in restricting writes, network, capabilities, and user
        # data access, not reads of world-readable system files.
        /nix/store/**                                                              r,

        # Icons, themes, shared data
        @{HOME}/.local/share/icons/**                                             r,
        @{HOME}/.local/share/themes/**                                            r,
        @{HOME}/.local/share/mime/**                                              r,
        # Flatpak-exported icons/themes/applications
        /var/lib/flatpak/exports/share/icons/**                                   r,
        /var/lib/flatpak/exports/share/themes/**                                  r,
        /var/lib/flatpak/exports/share/applications/                              r,
        /var/lib/flatpak/exports/share/applications/**                            r,

        # System config
        /etc/machine-id                                                           r,
        @{sys}/devices/system/cpu/**                                              r,

        # Hardware detection (GPU/PCI enumeration, active tty)
        @{sys}/bus/pci/devices/                                                   r,
        @{sys}/devices/pci*/**                                                    r,
        @{sys}/devices/virtual/tty/tty0/active                                    r,

        # Device access
        /dev/urandom                                                              r,
        /dev/random                                                               r,
        /dev/null                                                                 rw,
        /dev/zero                                                                 rw,
        /dev/log                                                                  w,
        # Terminal access (Chromium crash reporting, terminal detection)
        /dev/tty                                                                  rw,
        /dev/pts/@{int}                                                           rw,

        # Silencer
        deny /etc/opt/                                                            w,
        deny @{HOME}/.local/share/gvfs-metadata/*                                r,
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
          include <tunables/global>

          @{lib_dirs} = /nix/store/*-brave*/opt/brave.com/brave
          @{config_dirs} = @{HOME}/.config/BraveSoftware
          @{cache_dirs} = @{HOME}/.cache/BraveSoftware

          profile brave /nix/store/*-brave*/opt/brave.com/brave/brave ${modeFlag} {
            include <abstractions/chromium>

            # Brave binary exec chain (chrome-sandbox transitions to the
            # brave-sandbox profile; crashpad/management-service inherit)
            @{lib_dirs}/brave                       mrix,
            @{lib_dirs}/chrome-sandbox              rPx,
            @{lib_dirs}/chrome_crashpad_handler     rix,
            @{lib_dirs}/chrome-management-service   rix,

            # Brave-specific temporary files
            /tmp/.com.brave.Brave.*/**              rw,
          }
        '';
      };

      "brave-sandbox" = {
        state = cfg.desktop.browsers.brave.mode;
        profile = ''
          include <tunables/global>

          profile brave-sandbox /nix/store/*-brave*/opt/brave.com/brave/chrome-sandbox {
            include <abstractions/base>

            # NixOS shared libraries (see abstractions/chromium for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                       mr,

            capability setgid,
            capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability sys_resource,

            /nix/store/*-brave*/opt/brave.com/brave/chrome-sandbox mr,
            /nix/store/*-brave*/opt/brave.com/brave/brave          rPx,

            @{PROC}                                                r,
            @{PROC}/@{pids}/                                       r,
            owner @{PROC}/@{pid}/fd/                               r,
            owner @{PROC}/@{pid}/oom_adj                           rw,
            owner @{PROC}/@{pid}/oom_score_adj                     rw,

            include if exists <local/brave-sandbox>
          }
        '';
      };

      "brave-wrapper" = {
        state = cfg.desktop.browsers.brave.mode;
        profile = ''
          include <tunables/global>

          profile brave-wrapper /nix/store/*-brave*/bin/brave {
            include <abstractions/base>
            include <abstractions/consoles>

            # NixOS shared libraries (see abstractions/chromium for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                       mr,

            /nix/store/*-brave*/bin/**                               r,

            /nix/store/*/bin/{sh,bash,dash}                         rix,
            /nix/store/*coreutils*/bin/cat                         rix,
            /nix/store/*coreutils*/bin/dirname                     rix,
            /nix/store/*coreutils*/bin/mkdir                       rix,
            /nix/store/*coreutils*/bin/readlink                    rix,
            /nix/store/*coreutils*/bin/touch                       rix,
            /nix/store/*which*/bin/which                           rix,

            /nix/store/*-brave*/opt/brave.com/brave/brave          rPx,
            /nix/store/*-brave*/opt/brave.com/brave/brave-browser r,

            owner @{PROC}/@{pid}/fd/@{int}                         w,

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
          include <tunables/global>

          @{config_dirs} = @{HOME}/.config/Signal
          @{cache_dirs} = @{HOME}/.cache/signal-desktop

          profile signal-desktop /nix/store/*-signal-desktop-*/bin/signal-desktop ${modeFlag} {
            include <abstractions/electron>

            # Signal Desktop wrapper (inherits profile through electron exec chain)
            /nix/store/*-signal-desktop-*/bin/signal-desktop                       rix,

            # Chromium sandbox (separate profile with elevated capabilities)
            /nix/store/*-electron-unwrapped-*/libexec/electron/chrome-sandbox       rPx -> signal-desktop-chrome-sandbox,

            # Signal Desktop app resources
            /nix/store/*-signal-desktop-*/share/signal-desktop/**                   r,
            /nix/store/*-signal-desktop-*/share/signal-desktop/app.asar             mr,
            # Native node modules (libsignal crypto, ringrtc WebRTC) — need mmap
            /nix/store/*-signal-desktop-*/share/signal-desktop/app.asar.unpacked/**/*.node mr,

            # Signal Desktop flags
            owner @{HOME}/.config/signal-desktop-flags.conf                         r,

            # Downloads directory (for file sharing)
            owner @{HOME}/Downloads/**                                              rw,

            # Temporary files
            /tmp/signal-desktop-*/**                                                rw,

            # Camera (for video calls)
            /dev/video*                                                             rw,

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
          include <tunables/global>

          profile signal-desktop-chrome-sandbox /nix/store/*-electron-unwrapped-*/libexec/electron/chrome-sandbox {
            include <abstractions/base>

            # NixOS shared libraries (see abstractions/electron for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                       mr,

            capability setgid,
            capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability dac_override,

            /nix/store/*-electron-unwrapped-*/libexec/electron/chrome-sandbox       mr,
            /nix/store/*-electron-unwrapped-*/libexec/electron/electron             rPx -> signal-desktop,

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
    };
  };
}
