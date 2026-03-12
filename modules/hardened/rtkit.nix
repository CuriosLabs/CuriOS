{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.rtkit-daemon.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Hardened systemd configuration for rtkit-daemon.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.rtkit-daemon.enable {
    systemd.services.rtkit-daemon.serviceConfig = {
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      PrivateTmp = true;
      PrivateMounts = true;
      PrivateDevices = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = [ "~AF_INET6" "~AF_INET" "~AF_PACKET" ];
      MemoryDenyWriteExecute = true;
      DevicePolicy = "closed";
      LockPersonality = true;
      SystemCallFilter = [
        "~@keyring"
        "~@swap"
        "~@clock"
        "~@module"
        "~@obsolete"
        "~@cpu-emulation"
      ];
    };
  };
}

