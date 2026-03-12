{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.sshd.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Hardened systemd configuration for sshd.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.sshd.enable {
    systemd.services.sshd.serviceConfig = {
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectProc = "invisible";
      PrivateTmp = true;
      PrivateMounts = true;
      PrivateDevices = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      DevicePolicy = "closed";
      SystemCallFilter = [
        "~@keyring"
        "~@swap"
        "~@clock"
        "~@module"
        "~@obsolete"
        "~@cpu-emulation"
      ];
      SystemCallArchitectures = "native";
    };
  };
}

