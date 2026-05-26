{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "CuriOS hardened systemd configuration for docker.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.docker.enable {
    systemd.services.docker.serviceConfig = {
      NoNewPrivileges = true;
      ProtectSystem = "full";
      ProtectHome = "read-only";
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectProc = "invisible";
      PrivateTmp = true;
      PrivateMounts = true;
      RestrictRealtime = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_NETLINK"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = [
        "~user"
      ];
      MemoryDenyWriteExecute = true;
      SystemCallFilter = [
        "~@debug"
        "~@raw-io"
        "~@reboot"
        "~@clock"
        "~@module"
        "~@swap"
        "~@obsolete"
      ];
      SystemCallArchitectures = "native";
      CapabilityBoundingSet= [
        "~CAP_SYS_RAWIO"
        "~CAP_SYS_PTRACE"
        "~CAP_SYS_BOOT"
      ];
    };
  };
}