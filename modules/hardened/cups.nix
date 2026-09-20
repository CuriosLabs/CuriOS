{ config, lib, ... }:

let
  # Shared baseline for cupsd and cups-browsed (LAN IPP client).
  # Avoid PrivateDevices — breaks USB printers if used later.
  # Avoid ProtectSystem=strict without careful ReadWritePaths — cupsd
  # writes spool/cache/state under /var and config under /etc/cups.
  cupsServiceConfig = {
    NoNewPrivileges = true;
    ProtectSystem = "full";
    ProtectHome = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectClock = true;
    ProtectProc = "invisible";
    PrivateTmp = true;
    PrivateMounts = true;
    RestrictRealtime = true;
    RestrictNamespaces = true;
    RestrictSUIDSGID = true;
    # UNIX socket + LAN IPP/DNS; NETLINK for udev/device events.
    # AF_PACKET kept for SNMP/device discovery backends.
    RestrictAddressFamilies =
      [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" "AF_PACKET" ];
    MemoryDenyWriteExecute = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
    # Do not deny @privileged — cupsd setuid/setgid for job filters.
    SystemCallFilter = [
      "~@clock"
      "~@reboot"
      "~@debug"
      "~@module"
      "~@swap"
      "~@obsolete"
      "~@cpu-emulation"
    ];
    UMask = "0077";
  };
in {
  options = {
    curios.hardened.cups.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hardened systemd configuration for cups and cups-browsed.";
    };
  };

  config = lib.mkIf (config.curios.hardened.cups.enable
    && config.services.printing.enable) {
    systemd.services.cups.serviceConfig = cupsServiceConfig;
    systemd.services.cups-browsed.serviceConfig = cupsServiceConfig // {
      # browsed only talks to Avahi + local cupsd.
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    };
  };
}
