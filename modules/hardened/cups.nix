{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.cups.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Hardened systemd configuration for cups.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.cups.enable {
    systemd.services.cups.serviceConfig = {
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
      RestrictRealtime = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies =
        [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" "AF_PACKET" ];

      MemoryDenyWriteExecute = true;
      SystemCallFilter = [
        "~@clock"
        "~@reboot"
        "~@debug"
        "~@module"
        "~@swap"
        "~@obsolete"
        "~@cpu-emulation"
      ];
      SystemCallArchitectures = "native";
      LockPersonality = true;
    };
  };
}

