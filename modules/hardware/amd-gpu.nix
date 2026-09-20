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
      # Enable OpenCL using ROCm runtime library
      amdgpu.opencl.enable = lib.mkDefault true;
      graphics = {
        # Enable OpenGL
        enable = lib.mkDefault true;
        #enable32Bit = lib.mkDefault true;
      };
    };

    # Enable ROCm support for packages (HIP, etc.)
    nixpkgs.config.rocmSupport = true;

    # Load driver for Xorg and Wayland
    services.xserver = {
      enable = lib.mkDefault true;
      videoDrivers = lib.mkDefault [ "amdgpu" ];
    };

    # GUI AMD GPU controller + RadeonTOP
    environment.systemPackages = with pkgs; [ lact radeontop rocmPackages.clr ];
    systemd = {
      packages = with pkgs; [ lact ];
      services.lactd.wantedBy = [ "multi-user.target" ];
    };
  };
}
