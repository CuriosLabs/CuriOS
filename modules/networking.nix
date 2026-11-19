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
        # Only wifi and ethernet devices are affected; Docker, libvirt,
        # Tailscale, VPN interfaces are not managed by NetworkManager.
        dispatcherScripts = lib.mkIf config.curios.networking.useGlobalDns [{
          source = pkgs.writeScript "ignore-dhcp-dns.sh" ''
            #!${pkgs.runtimeShell}
            # Dispatcher variables: $1=iface, $2=action, $CONNECTION_ID, $DEVICE_IFACE
            if [ "$2" = "up" ] && [ -n "$CONNECTION_ID" ]; then
              devtype=$(${pkgs.networkmanager}/bin/nmcli -t -f GENERAL.TYPE device show "$DEVICE_IFACE" 2>/dev/null | cut -d: -f2)
              case "$devtype" in
                wifi|ethernet)
                  ${pkgs.networkmanager}/bin/nmcli connection modify "$CONNECTION_ID" \
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
