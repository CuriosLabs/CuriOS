{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.networkManager.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Hardened systemd configuration for NetworkManager.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.networkManager.enable {
    systemd.services.NetworkManager.serviceConfig = {
      NoNewPrivileges = true;
      ProtectHome = "read-only";
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectProc = "invisible";
      PrivateTmp = true;
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
    };
  };
}

