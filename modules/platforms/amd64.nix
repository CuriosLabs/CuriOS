# x86_64 AMD, Intel configurations

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.platform.amd64.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "x86_64 AMD/Intel CPUs configurations";
    };
  };

  config = lib.mkIf config.curios.platform.amd64.enable {
    boot = {
      kernelParams = if builtins.elem "kvm-amd" config.boot.kernelModules then [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
        "amd_pstate=active"
        "nosplit_lock_mitigate"
      ] else [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
