# Evince (GNOME Document Viewer) AppArmor profiles.
# Profiles: evince, evince-previewer, evinced, evince-thumbnailer

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.policies = {
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
    };
  };
}
