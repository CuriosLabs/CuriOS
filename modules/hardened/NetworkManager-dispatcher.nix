{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.networkManager-dispatcher.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Hardened systemd config for networkManager-dispatcher.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.networkManager-dispatcher.enable {
    systemd.services.NetworkManager-dispatcher.serviceConfig = {
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectProc = "invisible";
      PrivateTmp = true;
      PrivateMounts = true;
      RestrictRealtime = true;
      RestrictAddressFamilies =
        [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" "AF_PACKET" ];
      RestrictNamespaces = false;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      SystemCallFilter = [
        "~@module"
        "~@swap"
        "~@obsolete"
        "~@cpu-emulation"
        "ptrace"
      ];
      SystemCallArchitectures = "native";
      LockPersonality = true;
      CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW";
    };
  };
}

