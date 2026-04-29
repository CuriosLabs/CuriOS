{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.user.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Hardened systemd configuration for user.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.user.enable {
    systemd.services."user@".serviceConfig = {
      ProtectSystem = "strict";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectProc = "invisible";
      PrivateTmp = true;
      PrivateNetwork = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" "AF_BLUETOOTH" ];
      RestrictNamespaces = false;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallFilter = [
        "~@keyring"
        "~@swap"
        "~@debug"
        "~@module"
        "~@obsolete"
        "~@cpu-emulation"
      ];
      SystemCallArchitectures = "native";
    };
  };
}

