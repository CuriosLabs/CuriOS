# Intel GPU configuration
# See: https://nixos.wiki/wiki/Intel_Graphics
# See: https://nixos.wiki/wiki/Accelerated_Video_Playback

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.hardware.intelGpu.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enabling Intel GPU configuration";
    };
  };

  config = lib.mkIf config.curios.hardware.intelGpu.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      # Some Intel GPU may require this if X Server fail to start.
      # Get the GPU device ID from the command:
      # lspci -nn | grep VGA
      # and replace it below:
      #kernelParams = [ "i915.force_probe=<device ID>" ];
    };

    # Intel GPU
    hardware = {
      graphics = {
        # Enable OpenGL
        enable = lib.mkDefault true;
        #enable32Bit = lib.mkDefault true;
        # Add OpenGL, Vulkan, VA-API drivers:
        extraPackages = with pkgs; [
          vpl-gpu-rt # for newer GPUs
          intel-media-driver # LIBVA_DRIVER_NAME=iHD (for HD Graphics starting Broadwell (2014) and newer)
          intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
          libvdpau-va-gl
        ];
      };
    };

    # Force intel-media-driver
    environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };

    # Load driver for Xorg and Wayland
    services.xserver.enable = lib.mkDefault true;
    #services.xserver.videoDrivers = lib.mkDefault [ "amdgpu" ];
  };
}
