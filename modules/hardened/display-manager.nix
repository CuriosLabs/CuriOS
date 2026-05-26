{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.display-manager.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Hardened systemd configuration for display-manager.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.display-manager.enable {
    systemd.services.display-manager.serviceConfig = {
      ProtectSystem = "full";
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectKernelModules = true;
      PrivateMounts = true;
      PrivateIPC = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      RestrictNamespaces = [ "~cgroup" ];
      RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" ];
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = [
        "~@obsolete"
        "~@clock"
        "~@swap"
        "~@module"
        "~@reboot"
        "~@raw-io"
        "~@debug"
      ];
      SystemCallArchitectures = "native";
      LockPersonality = true;
      IPAddressDeny = [ "0.0.0.0/0" "::/0" ];
      CapabilityBoundingSet = [
        "CAP_SYS_ADMIN"
        "CAP_SETUID"
        "CAP_SETGID"
        "CAP_SETPCAP"
        "CAP_KILL"
        "CAP_SYS_TTY_CONFIG"
        "CAP_DAC_OVERRIDE"
        "CAP_DAC_READ_SEARCH"
        "CAP_FOWNER"
        "CAP_IPC_OWNER"
        "CAP_FSETID"
        "CAP_SETFCAP"
        "CAP_CHOWN"
      ];
      DeviceAllow = [
        "/dev/tty1 rw"
        "/dev/tty7 rw"
      ];
      DevicePolicy = "closed";
      UMask = 0022;
      LogLevelMax = "info";
      KeyringMode = lib.mkForce "private";
    };
  };
}

