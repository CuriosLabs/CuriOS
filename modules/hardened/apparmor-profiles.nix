# NixOS-path AppArmor profiles for sandboxed apps that need unprivileged
# user namespaces. Bridges the gap between upstream pkgs.apparmor-profiles
# (which targets FHS paths like /usr/bin/...) and NixOS's /nix/store layout.
#
# When curios.hardened.anssi.reinforced.ruleUsernsRestrict is enabled, the
# kernel transitions unconfined binaries creating userns to the
# unprivileged_userns profile (from pkgs.apparmor-profiles) which strips
# CAP_NET_ADMIN. This blocks page-cache poisoning LPEs (CVE-2026-46331,
# CVE-2026-43503) but also breaks legitimate sandboxed apps.
#
# This module provides equivalent profiles with /nix/store/*-<pkg>-*/bin/...
# globs so they attach on NixOS, granting userns, to the apps that need it.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
  usernsRestrictActive = anssi.enable && anssi.rule45 && anssi.ruleUsernsRestrict;

  # Generate a simple unconfined AppArmor profile that grants userns
  # permission to a NixOS store path glob, matching the upstream
  # pkgs.apparmor-profiles pattern (flags=(unconfined) + userns,).
  mkUsernsProfile = name: pathGlob: upstreamName: {
    state = "enforce";
    profile = ''
      abi <abi/4.0>,
      include <tunables/global>

      profile ${name} ${pathGlob} flags=(unconfined) {
        userns,
        include if exists <local/${upstreamName}>
      }
    '';
  };
in
{
  # Declare options
  options = {
    curios.hardened.apparmor-profiles = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Ship NixOS-path AppArmor profiles for sandboxed apps that need unprivileged user namespaces (Brave, Chromium, Flatpak, rootless containers, etc.). Requires curios.hardened.anssi.reinforced.rule45 (AppArmor) and curios.hardened.anssi.reinforced.ruleUsernsRestrict to be enabled.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf (cfg.enable && usernsRestrictActive) {
    security.apparmor.policies = lib.mkMerge [
      # Load the upstream unprivileged_userns transition profile.
      # Required for kernel.apparmor_restrict_unprivileged_userns=1 to
      # actually transition unconfined processes and strip CAP_NET_ADMIN.
      # Without this, the kernel restriction has no target profile.
      {
        "unprivileged_userns" = {
          state = "enforce";
          path = "${pkgs.apparmor-profiles}/etc/apparmor.d/unprivileged_userns";
        };
      }

      # Brave
      (lib.optionalAttrs config.curios.desktop.browser.brave.enable {
        "nixos-brave" = mkUsernsProfile "nixos-brave" "/nix/store/*-brave-*/bin/brave" "brave";
      })

      # Ungoogled Chromium
      (lib.optionalAttrs config.curios.desktop.browser.chromium.enable {
        "nixos-chromium" =
          mkUsernsProfile "nixos-chromium" "/nix/store/*-ungoogled-chromium-*/bin/chromium"
            "chromium";
      })

      # Vivaldi
      (lib.optionalAttrs config.curios.desktop.browser.vivaldi.enable {
        "nixos-vivaldi" =
          mkUsernsProfile "nixos-vivaldi" "/nix/store/*-vivaldi-*/bin/vivaldi"
            "vivaldi-bin";
      })

      # Flatpak (services.flatpak.enable is hardcoded true in CuriOS)
      (lib.optionalAttrs config.services.flatpak.enable {
        "nixos-flatpak" = mkUsernsProfile "nixos-flatpak" "/nix/store/*-flatpak-*/bin/flatpak" "flatpak";
      })

      # Signal Desktop (Electron/Chromium sandbox)
      (lib.optionalAttrs config.curios.desktop.chat.signal.enable {
        "nixos-signal-desktop" =
          mkUsernsProfile "nixos-signal-desktop" "/nix/store/*-signal-desktop-*/bin/signal-desktop"
            "signal-desktop";
      })

      # Discord (Electron/Chromium sandbox)
      (lib.optionalAttrs
        (config.curios.desktop.chat.discord.enable && config.curios.platform.amd64.enable)
        {
          "nixos-discord" = mkUsernsProfile "nixos-discord" "/nix/store/*-discord-*/bin/Discord" "Discord";
        }
      )

      # Rootless container tools (Podman runs rootless by default; rootless
      # Docker needs virtualisation.docker.rootless.enable = true)
      (lib.optionalAttrs
        (
          config.curios.virtualisation.enable
          && (config.curios.virtualisation.podman.enable || config.curios.virtualisation.docker.enable)
        )
        {
          "nixos-podman" = mkUsernsProfile "nixos-podman" "/nix/store/*-podman-*/bin/podman" "podman";
          "nixos-rootlesskit" =
            mkUsernsProfile "nixos-rootlesskit" "/nix/store/*-rootlesskit-*/bin/rootlesskit"
              "rootlesskit";
          "nixos-slirp4netns" =
            mkUsernsProfile "nixos-slirp4netns" "/nix/store/*-slirp4netns-*/bin/slirp4netns"
              "rootlesskit";
        }
      )
    ];
  };
}
