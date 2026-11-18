# Networking settings

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.networking = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED CuriOS networking options.";
      };
      useGlobalDns = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "Ignore DNS servers received via DHCP on NetworkManager-managed interfaces.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.networking.enable {
    networking = {
      # Enables wireless support via wpa_supplicant OR
      wireless.enable = lib.mkDefault false;
      # via networkmanager: easiest to use and most distros use this by default.
      networkmanager = {
        enable = lib.mkDefault true;
        # Do not let NetworkManager manage DNS at all: DHCP DNS servers are not
        # pushed to systemd-resolved, so the global config (DoT + DNSSEC +
        # custom nameservers from networking.nameservers) is used on all NM
        # interfaces. /etc/resolv.conf is managed by NixOS (stub-resolv.conf).
        # VPN interfaces (Tailscale, Proton...) set their own DNS directly via
        # D-Bus to resolved and are not affected.
        # mkForce: override the "systemd-resolved" default set by NixOS
        # when services.resolved.enable = true (see nixos/modules/system/boot/resolved.nix)
        dns = lib.mkIf config.curios.networking.useGlobalDns (lib.mkForce "none");
      };
    };
  };
}
