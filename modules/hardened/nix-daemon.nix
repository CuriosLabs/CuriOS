{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardened.nix-daemon.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Hardened systemd configuration for nix-daemon.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.hardened.nix-daemon.enable {
    systemd.services.nix-daemon.serviceConfig = {
      NoNewPrivileges = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateDevices = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      RestrictNamespaces = [ "~cgroup" ];
      RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" "AF_INET6" "AF_INET" ];
      CapabilityBoundingSet = [
        "~CAP_SYS_CHROOT"
        "~CAP_BPF"
        "~CAP_AUDIT_WRITE"
        "~CAP_AUDIT_CONTROL"
        "~CAP_AUDIT_READ"
        "~CAP_SYS_PTRACE"
        "~CAP_SYS_NICE"
        "~CAP_SYS_RESOURCE"
        "~CAP_SYS_RAWIO"
        "~CAP_SYS_TIME"
        "~CAP_SYS_PACCT"
        "~CAP_LINUX_IMMUTABLE"
        "~CAP_IPC_LOCK"
        "~CAP_WAKE_ALARM"
        "~CAP_SYS_TTY_CONFIG"
        "~CAP_SYS_BOOT"
        "~CAP_LEASE"
        "~CAP_BLOCK_SUSPEND"
        "~CAP_MAC_ADMIN"
        "~CAP_MAC_OVERRIDE"
      ];
      SystemCallErrorNumber = "EPERM";
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "~@resources"
        "~@module"
        "~@obsolete"
        "~@debug"
        "~@reboot"
        "~@swap"
        "~@cpu-emulation"
        "~@clock"
        "~@raw-io"
      ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      DevicePolicy = "closed";
      UMask = 77;
    };
  };
}

