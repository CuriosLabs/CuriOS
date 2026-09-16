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
    systemd.services.docker.serviceConfig =
      lib.mkIf (!config.curios.virtualisation.docker.rootless) {
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

    # Rootless dockerd runs as a user unit and needs user namespaces plus
    # write access to $HOME (data-root). Keep a lighter sandbox.
    systemd.user.services.docker.serviceConfig =
      lib.mkIf config.curios.virtualisation.docker.rootless {
        NoNewPrivileges = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectClock = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_NETLINK"
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = [
          "~CAP_SYS_RAWIO"
          "~CAP_SYS_PTRACE"
          "~CAP_SYS_BOOT"
        ];
      };
  };
}
