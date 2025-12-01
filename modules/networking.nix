# Networking settings

{ config, lib, ... }: {
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
      # Enables wireless support via wpa_supplicant OR
      wireless.enable = false;
      # via networkmanager: easiest to use and most distros use this by default.
      networkmanager.enable = true;
    };
  };
}
