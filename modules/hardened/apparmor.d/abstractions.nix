# CuriOS AppArmor abstractions — security.apparmor.includes.
# Reusable rule sets shared across profiles, mirroring /etc/apparmor.d/abstractions/.

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
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
        deny @{HOME}/**/*.key                            r,
        deny @{HOME}/**/*.kdbx                           r,
      '';

      "abstractions/curios/secrets-deny-browsers" = ''
        abi <abi/4.0>,
        deny @{HOME}/.mozilla/**                         r,
        deny @{HOME}/.config/BraveSoftware/**            r,
        deny @{HOME}/.config/chromium/**                 r,
        deny @{HOME}/.config/google-chrome/**            r,
      '';

      "abstractions/curios/dbus-restrict" = ''
        abi <abi/4.0>,
        # CuriOS D-Bus restriction abstraction.
        # Based on <abstractions/dbus-session-strict> (apparmor-profiles) for
        # secure-by-default D-Bus mediation, with an explicit allowlist of
        # benign services and an explicit denylist of secret/keyring services.
        #
        # Usage: include this abstraction INSTEAD of granting blanket
        # `owner @{run}/user/@{uid}/bus rw,` access.
        #
        # NOT ENFORCED on NixOS 26.05. dbus rules are consulted by the bus
        # daemon, not by the kernel on the session socket. The default bus is
        # dbus-broker, which does not implement AppArmor mediation: with
        # <apparmor mode="enabled"/> it logs "AppArmor enabled, but not
        # supported" and allows the message (bus1/dbus-broker#169). The NixOS
        # dbus-daemon package is not linked to libapparmor either, so
        # services.dbus.implementation = "dbus" would not mediate today.
        # options.nix already sets services.dbus.apparmor = "enabled" when
        # ANSSI R45 is on, so the XML is ready. These peer=() rules will
        # start applying when NixOS ships a mediating bus (dbus-daemon built
        # with libapparmor, or dbus-broker with AppArmor support). Until
        # then, the socket rule below is enough to reach every session
        # service, including org.freedesktop.secrets.

        # Base: socket access + org.freedesktop.DBus (Hello, AddMatch, etc.)
        # If apparmor-profiles is not installed, fall back to socket-only access.
        include if exists <abstractions/dbus-session-strict>

        # Fallback: ensure socket access even without dbus-session-strict
        owner @{run}/user/@{uid}/bus                                           rw,

        # ── Allowed: benign session bus services ──────────────────────────
        # send/receive are message rules: the bus name belongs in peer=().
        # A bare name= is a service (bind) conditional and the parser rejects
        # it with send/receive (apparmor.d(5), parser/dbus.cc):
        #   dbus "send" and/or "receive" accesses cannot be used with
        #   service rule conditionals
        # Desktop notifications
        dbus (send, receive) bus=session peer=(name=org.freedesktop.Notifications),

        # XDG portals (file chooser, open URI, settings, etc.)
        dbus (send, receive) bus=session peer=(name=org.freedesktop.portal.*),

        # Power management / battery info
        dbus (send, receive) bus=session peer=(name=org.freedesktop.UPower),
        dbus (send, receive) bus=session peer=(name=org.freedesktop.PowerManagement),

        # systemd user instance (service status, timers)
        dbus (send, receive) bus=session peer=(name=org.freedesktop.systemd1),

        # login1 (session info, inhibit/shutdown requests)
        dbus (send, receive) bus=session peer=(name=org.freedesktop.login1),

        # NetworkManager (network status, not credentials)
        dbus (send, receive) bus=session peer=(name=org.freedesktop.NetworkManager),

        # Bluetooth (device discovery, not pairing secrets)
        dbus (send, receive) bus=session peer=(name=org.bluez),

        # Accessibility (screen readers)
        dbus (send, receive) bus=session peer=(name=org.a11y.*),

        # CUPS printing
        dbus (send, receive) bus=session peer=(name=org.cups.cupsd),

        # Avahi / mDNS (local network discovery)
        dbus (send, receive) bus=session peer=(name=org.freedesktop.Avahi),

        # ── Denied: secret/keyring services (explicit, defense in depth) ──
        # Even with dbus-session-strict these are blocked by default,
        # but we deny them explicitly for documentation and defense in depth.

        # GNOME Keyring / freedesktop secrets service (stores passwords, keys)
        deny dbus (send, receive) bus=session peer=(name=org.freedesktop.secrets),
        deny dbus (send, receive) bus=session peer=(name=org.freedesktop.secrets.*),

        # KDE Wallet (KWallet) — stores passwords, keys
        deny dbus (send, receive) bus=session peer=(name=org.kde.kwalletd),
        deny dbus (send, receive) bus=session peer=(name=org.kde.kwalletd*),
        deny dbus (send, receive) bus=session peer=(name=org.kde.ksecretd),

        # GNOME Keyring (legacy)
        deny dbus (send, receive) bus=session peer=(name=org.gnome.keyring),
        deny dbus (send, receive) bus=session peer=(name=org.gnome.keyring.*),

        # Permission store (portal permissions may contain sensitive paths)
        deny dbus (send, receive) bus=session peer=(name=org.freedesktop.impl.portal.PermissionStore),

        # SSH agent (can be used to sign with SSH keys)
        deny dbus (send, receive) bus=session peer=(name=com.github.ssh-agent),
      '';

      "abstractions/curios/agents-skills" = ''
        abi <abi/4.0>,
        # CuriOS abstraction for AI agent skills (opencode, claude-code, codex, …).
        # Covers the shared needs of agent skills:
        #   - ~/.agents/       — skill definitions and executable scripts
        #   - ~/.npm/          — npm cache, logs, npx-installed tools
        #   - Brave browser    — skills like brave-tools launch the browser

        # ── Agent skills (~/.agents/skills/) ──────────────────────────────
        # Skills are markdown/prompt files loaded by the agent runtime.
        # 'rix' (restricted inherit exec) allows running skill scripts
        # (e.g. brave-tools/scripts/*) while keeping them confined:
        # they inherit the calling profile, so secrets-deny still applies.
        # 'w' needed because skills may run `npm install` in their directory
        # (e.g. brave-tools/node_modules/).
        owner @{HOME}/.agents/                                                 rwk,
        owner @{HOME}/.agents/**                                               rwkrix,

        # ── npm cache and logs (~/.npm/) ──────────────────────────────────
        # _cacache/  — package cache (create, delete, hard links for dedup)
        # _logs/     — debug logs (create new, delete old)
        # _npx/      — npx-installed tools (execute .js scripts via shebang)
        # 'rix' on .js: npx executes scripts directly (#!/usr/bin/env node).
        # Note: secrets-deny blocks ~/.npmrc (auth tokens) separately.
        owner @{HOME}/.npm/                                                    rwk,
        owner @{HOME}/.npm/**                                                  rwklm,
        owner @{HOME}/.npm/**/*.js                                             rix,

        # ── Global npm packages (~/.npm-packages/) ─────────────────────────
        # User-installed global packages (npm install -g --prefix ~/.npm-packages).
        # bin/ contains symlinks → lib/node_modules/*/dist/bin.js (with shebang).
        # AppArmor resolves symlinks, so rix must be on the resolved .js path.
        # 'rix' on .js: shell execs the script, kernel runs /usr/bin/env node.
        owner @{HOME}/.npm-packages/                                           rwk,
        owner @{HOME}/.npm-packages/**                                         rwklm,
        owner @{HOME}/.npm-packages/**/*.js                                    rix,

        # ── XDG cache directory (~/.cache/) ───────────────────────────────
        # Application caches. Skills and tools (basecamp, etc.) write temp
        # files, cached responses, and completion data here.
        # 'c' (create) needed for .tmp files, 'd' (delete) for cache cleanup.
        owner @{HOME}/.cache/                                                  rwk,
        owner @{HOME}/.cache/**                                                rwklm,

        # ── Brave browser (for browser-automation skills) ──────────────────
        # Skills like brave-tools launch Brave.
        # Execution chain:
        #   bin/brave (wrapper script, rix → inherits calling profile)
        #     → exec bin/.brave-wrapped
        #       → symlink to ../opt/brave.com/brave/brave-browser
        #         → AppArmor resolves symlink, checks brave-browser path
        #           → rPx -> brave transitions to the brave profile
        #
        # Key insight: bin/.brave-wrapped is a SYMLINK to brave-browser.
        # AppArmor resolves symlinks before checking, so the rule must be on
        # brave-browser (the resolved path), not on .brave-wrapped.
        #
        # Note: bin/brave uses rix (not rPx -> brave-wrapper) to avoid
        # conflicting x modifiers with the general /nix/store/*/bin/* rix
        # rule in the calling profile.
        /nix/store/*-brave-*/bin/brave                                         rix,
        /nix/store/*-brave-*/opt/brave.com/brave/brave                        rPx -> brave,
        /nix/store/*-brave-*/opt/brave.com/brave/brave-browser                rPx -> brave,
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
        ${pkgs.electron_44}/bin/electron                                       rix,
        ${pkgs.electron_44.unwrapped}/libexec/electron/electron                mrix,
        ${pkgs.electron_44.unwrapped}/libexec/electron/chrome_crashpad_handler rix,


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
        ${pkgs.electron_44.unwrapped}/libexec/electron/*.so*                   mr,
        ${pkgs.electron_44.unwrapped}/libexec/electron/*.pak                   r,
        ${pkgs.electron_44.unwrapped}/libexec/electron/*.dat                   r,
        ${pkgs.electron_44.unwrapped}/libexec/electron/*.bin                   r,
        ${pkgs.electron_44.unwrapped}/libexec/electron/locales/**              r,
        ${pkgs.electron_44.unwrapped}/libexec/electron/resources/**            r,
        ${pkgs.electron_44.unwrapped}/libexec/electron/vk_swiftshader_icd.json r,


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
  };
}
