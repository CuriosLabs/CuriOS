# CuriOS NixOS-path AppArmor profiles.
# See pkgs.apparmor-profiles and security.apparmor options.
# `nixos-option security.lsm`, `aa-enabled`, `sudo aa-status`
# `eza -l -tree /etc/apparmor.d/`
# Useful commands:
# `sudo aa-status` `sudo aa-status --complaining`
# `sudo ausearch -m AVC -ts today -c brave 2>/dev/null || sudo grep "apparmor=\"DENIED\"" /var/log/audit/audit.log | grep -i brave`
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
    };
  };

  config = mkIf (cfg.enable && anssi.enable && anssi.rule45) {
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
    };
  };
}
