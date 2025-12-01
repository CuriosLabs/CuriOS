# AMD GPU configuration
# See: https://nixos.wiki/wiki/AMD_GPU

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.hardware.amdGpu.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enabling AMD GPU configuration";
    };
  };

  config = lib.mkIf config.curios.hardware.amdGpu.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      initrd.kernelModules = [ "amdgpu" ];
      # Ban CPU integrated GPU, if any
      #blacklistedKernelModules = [ "i915" ];
    };

    # AMD GPU
    hardware = {
      graphics = {
        # Enable OpenGL
        enable = lib.mkDefault true;
        #enable32Bit = lib.mkDefault true;
      };
    };

    # Load driver for Xorg and Wayland
    services.xserver.enable = lib.mkDefault true;
    services.xserver.videoDrivers = lib.mkDefault [ "amdgpu" ];

    # GUI AMD GPU controller + RadeonTOP
    environment.systemPackages = with pkgs; [ lact radeontop ];
    systemd.packages = with pkgs; [ lact ];
    systemd.services.lactd.wantedBy = [ "multi-user.target" ];
  };
}
