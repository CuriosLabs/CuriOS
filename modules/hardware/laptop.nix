# Laptop hardware related packages.

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardware.laptop.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Laptop battery optimizer configuration - conflict with power-profiles-daemon";
    };
  };

  config = lib.mkIf config.curios.hardware.laptop.enable {
    # TLP - Optimize Linux Laptop Battery Life
    # See: https://linrunner.de/tlp/
    # See: sudo tlp-stat --help
    # COSMIC use power-profiles-daemon, we have to force it off
    services.power-profiles-daemon.enable = lib.mkForce false;
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # Battery care - prevent the battery from charging fully to preserve lifetime.
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;

        CPU_MAX_PERF_ON_AC = 100;
        CPU_MAX_PERF_ON_BAT = 60;
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
      };
    };
  };
}
