# Central platform option definitions to avoid circular imports in platform modules.
{ lib, ... }: {
  options.curios.platform = {
    rpi4.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "REQUIRED config on Raspberry PI 4 platform ONLY.";
    };
    rpi5.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "REQUIRED config on Raspberry PI 5 platform ONLY.";
    };
  };
}
