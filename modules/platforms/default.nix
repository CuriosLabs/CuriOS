# Central platform option definitions to avoid circular imports in platform modules.
{ lib, ... }: {
  imports = [ ./amd64.nix ./rpi4.nix ];

  options.curios.platform = {
    amd64.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "REQUIRED config on x86_64 AMD/Intel CPUs platforms.";
    };
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
