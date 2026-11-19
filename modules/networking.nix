# Networking settings

{ config, lib, pkgs, ... }: {
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
        # Force ignore-auto-dns on Wi-Fi/Ethernet connections when they come up.
        # Note: ipv4.ignore-auto-dns is NOT a valid [connection] default in
        # NetworkManager.conf (see man 5 NetworkManager.conf), and profiles created
        # by desktop applets (COSMIC) do not inherit global defaults anyway.
        # The dispatcher script sets it directly on the profile via nmcli.
        # Only 802-11-wireless and 802-3-ethernet are affected; Docker, libvirt,
        # Tailscale, VPN interfaces are not managed by NetworkManager.
        dispatcherScripts = lib.mkIf config.curios.networking.useGlobalDns [{
          source = pkgs.writeScript "ignore-dhcp-dns.sh" ''
            #!${pkgs.runtimeShell}
            if [ "$2" = "up" ]; then
              case "$CONNECTION_TYPE" in
                802-11-wireless|802-3-ethernet)
                  ${pkgs.networkmanager}/bin/nmcli connection modify "$CONNECTION" \
                    ipv4.ignore-auto-dns yes \
                    ipv6.ignore-auto-dns yes 2>/dev/null || true
                  ;;
              esac
            fi
          '';
          type = "basic";
        }];
      };
    };
  };
}
