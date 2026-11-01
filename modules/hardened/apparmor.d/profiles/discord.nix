# Discord AppArmor profiles.
# Profiles: discord, discord-sandbox

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.policies = {
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
    };
  };
}
