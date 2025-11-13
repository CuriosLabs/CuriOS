# Networking settings

{ config, lib, ... }:
{
  # Declare options
  options = {
    curios.networking.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CuriOS networking options.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.networking.enable {
    networking = {
      wireless.enable = false;  # Enables wireless support via wpa_supplicant OR
      networkmanager.enable = true;  # Easiest to use and most distros use this by default.
    };
  };
}
