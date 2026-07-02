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

        # Chromium sandbox requires user namespaces
        userns,

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

        # Temporary files
        /tmp/.org.chromium.Chromium.*/**                                           rw,
        owner @{HOME}/.tmp/**                                                      rw,

        # /proc access for Chromium sandbox
        owner @{PROC}/@{pid}/fd/                                                   r,
        owner @{PROC}/@{pid}/fd/@{int}                                             w,
        owner @{PROC}/@{pid}/maps                                                  r,
        owner @{PROC}/@{pid}/stat                                                  r,
        owner @{PROC}/@{pid}/status                                                r,
        owner @{PROC}/@{pid}/task/                                                 r,
        owner @{PROC}/@{pid}/task/@{tid}/comm                                      rw,
        owner @{PROC}/@{pid}/cmdline                                               r,
        owner @{PROC}/@{pid}/environ                                               r,
        owner @{PROC}/@{pid}/oom_adj                                               r,
        owner @{PROC}/@{pid}/oom_score_adj                                         rw,
        owner @{PROC}/@{pid}/cgroup                                                r,
        owner @{PROC}/@{pid}/mounts                                                r,
        owner @{PROC}/@{pid}/mountinfo                                             r,
        owner @{PROC}/@{pid}/smaps_rollup                                          r,
        owner @{PROC}/@{pid}/limits                                                r,
        @{PROC}/                                                                   r,
        @{PROC}/sys/kernel/yama/ptrace_scope                                       r,

        # DRI / GPU access
        /dev/dri/**                                                                rw,
        /dev/shm/**                                                                rw,

        # Wayland / X11
        owner @{run}/user/@{uid}/wayland-*                                         rw,
        /tmp/.X11-unix/X*                                                          rw,

        # D-Bus
        owner @{run}/user/@{uid}/bus                                               rw,

        # PipeWire / PulseAudio
        owner @{run}/user/@{uid}/pipewire-*                                        rw,
        @{run}/user/@{uid}/pulse/**                                                rw,

        # GTK
        owner @{HOME}/.config/gtk-3.0/**                                           r,
        owner @{HOME}/.config/gtk-4.0/**                                           r,

        # Icons, themes, shared data
        @{HOME}/.local/share/icons/**                                              r,
        @{HOME}/.local/share/themes/**                                             r,
        @{HOME}/.local/share/mime/**                                               r,

        # System config
        /etc/machine-id                                                            r,
        @{sys}/devices/system/cpu/**                                               r,

        # Device access
        /dev/urandom                                                               r,
        /dev/random                                                                r,
        /dev/null                                                                  rw,
        /dev/zero                                                                  rw,
        /dev/log                                                                   w,

        # Silencer
        deny /etc/opt/                                                             w,
        deny @{HOME}/.local/share/gvfs-metadata/*                                 r,
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

          profile brave /nix/store/*-brave*/opt/brave.com/brave/brave ${modeFlag} {
            include <abstractions/base>
            include <abstractions/nameservice>
            include <abstractions/fonts>
            include <abstractions/dconf>
            include <abstractions/ssl_certs>

            # Chromium sandbox requires user namespaces
            userns,

            # Nix store paths for Brave
            /nix/store/*-brave*/opt/brave.com/brave/brave          mrix,
            /nix/store/*-brave*/opt/brave.com/brave/*.so*          mr,
            /nix/store/*-brave*/opt/brave.com/brave/WidevineCdm/** mrwk,
            /nix/store/*-brave*/opt/brave.com/brave/chrome-sandbox rPx,
            /nix/store/*-brave*/opt/brave.com/brave/chrome_crashpad_handler rix,
            /nix/store/*-brave*/opt/brave.com/brave/chrome-management-service rix,

            # Network access
            network inet dgram,
            network inet6 dgram,
            network inet stream,
            network inet6 stream,
            network netlink raw,

            # User config and cache
            owner @{HOME}/.config/BraveSoftware/**                 rwk,
            owner @{HOME}/.cache/BraveSoftware/**                  rwk,

            # Temporary files
            owner @{HOME}/.tmp/**                                  rw,
            /tmp/.org.chromium.Chromium.*/**                       rw,
            /tmp/.com.brave.Brave.*/**                             rw,

            # /proc access for Chromium sandbox
            owner @{PROC}/@{pid}/fd/                               r,
            owner @{PROC}/@{pid}/fd/@{int}                         w,
            owner @{PROC}/@{pid}/maps                              r,
            owner @{PROC}/@{pid}/stat                              r,
            owner @{PROC}/@{pid}/status                            r,
            owner @{PROC}/@{pid}/task/                             r,
            owner @{PROC}/@{pid}/task/@{tid}/comm                  rw,
            owner @{PROC}/@{pid}/cmdline                           r,
            owner @{PROC}/@{pid}/environ                           r,
            owner @{PROC}/@{pid}/oom_adj                           r,
            owner @{PROC}/@{pid}/oom_score_adj                     rw,
            owner @{PROC}/@{pid}/cgroup                            r,
            owner @{PROC}/@{pid}/mounts                            r,
            owner @{PROC}/@{pid}/mountinfo                         r,
            owner @{PROC}/@{pid}/smaps_rollup                      r,
            owner @{PROC}/@{pid}/limits                            r,
            @{PROC}/                                               r,
            @{PROC}/sys/kernel/yama/ptrace_scope                   r,

            # DRI / GPU access
            /dev/dri/**                                            rw,
            /dev/shm/**                                            rw,

            # Wayland / X11
            owner @{run}/user/@{uid}/wayland-*                     rw,
            /tmp/.X11-unix/X*                                      rw,

            # D-Bus
            owner @{run}/user/@{uid}/bus                           rw,

            # PipeWire / PulseAudio
            owner @{run}/user/@{uid}/pipewire-*                    rw,
            @{run}/user/@{uid}/pulse/**                            rw,

            # GTK
            owner @{HOME}/.config/gtk-3.0/**                       r,

            # Icons, themes, shared data
            @{HOME}/.local/share/icons/**                          r,
            @{HOME}/.local/share/themes/**                         r,
            @{HOME}/.local/share/mime/**                           r,

            # System config
            /etc/machine-id                                        r,
            @{sys}/devices/system/cpu/**                           r,

            # Device access
            /dev/urandom                                           r,
            /dev/random                                            r,
            /dev/null                                              rw,
            /dev/zero                                              rw,
            /dev/log                                               w,

            # Silencer
            deny /etc/opt/                                         w,
            deny @{HOME}/.local/share/gvfs-metadata/*              r,
          }
        '';
      };

      "brave-sandbox" = {
        state = cfg.desktop.browsers.brave.mode;
        profile = ''
          include <tunables/global>

          profile brave-sandbox /nix/store/*-brave*/opt/brave.com/brave/chrome-sandbox {
            include <abstractions/base>

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
