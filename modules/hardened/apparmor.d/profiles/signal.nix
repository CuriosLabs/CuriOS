# Signal Desktop AppArmor profiles.
# Profiles: signal-desktop, signal-desktop-chrome-sandbox

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.policies = {
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
            ${pkgs.electron_44}/libexec/electron/chrome-sandbox                rPx -> signal-desktop-chrome-sandbox,

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

          profile signal-desktop-chrome-sandbox ${pkgs.electron_44}/libexec/electron/chrome-sandbox {
            include <abstractions/base>
            include <abstractions/curios/gconv>

            # NixOS shared libraries (see abstractions/electron for rationale)
            /nix/store/*/lib{,32,64}/**.so*                                    mr,

            capability setgid,
            capability setuid,
            capability sys_admin,
            capability sys_chroot,
            capability dac_override,

            ${pkgs.electron_44}/libexec/electron/chrome-sandbox                mr,
            ${pkgs.electron_44}/libexec/electron/electron                      rPx -> signal-desktop,

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
    };
  };
}
