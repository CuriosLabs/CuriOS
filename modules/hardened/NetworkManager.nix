{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.networkManager.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Hardened systemd configuration for NetworkManager - WARNING: proton-vpn bug.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.networkManager.enable {
    systemd.services.NetworkManager.serviceConfig = {
      NoNewPrivileges = true;
      ProtectHome = true;
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
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      SystemCallFilter = [
        "~@mount"
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

