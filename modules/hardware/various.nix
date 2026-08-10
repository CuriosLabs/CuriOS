# Various hardware configuration

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardware.various = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable various hardware support.";
      };
      i2c.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable i2c devices support.";
      };
    };
  };

  config = lib.mkIf config.curios.hardware.various.enable {
    hardware = {
      i2c = {
        # Enable i2c
        enable = lib.mkDefault config.curios.hardware.various.i2c.enable;
      };
    };
  };
}
