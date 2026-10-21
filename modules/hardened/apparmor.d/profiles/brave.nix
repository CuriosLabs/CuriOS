# Brave browser AppArmor profiles.
# Profiles: brave, brave-sandbox, brave-wrapper

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
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

            # Brave-specific temporary files.
            # Three rules needed: the dir itself (no trailing slash),
            # the dir with trailing slash (for listing), and contents.
            # Same pattern as chromium-engine's .org.chromium.Chromium.* rules.
            owner /tmp/.com.brave.Brave.*            rwk,
            owner /tmp/.com.brave.Brave.*/           rwk,
            owner /tmp/.com.brave.Brave.*/**         rwk,

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
    };
  };
}
