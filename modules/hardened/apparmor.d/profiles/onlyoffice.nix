# OnlyOffice Desktop Editors AppArmor profile.
# Profile: onlyoffice-desktopeditors

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.policies = {
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
    };
  };
}
