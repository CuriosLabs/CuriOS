# Add Nvidia GPU configuration
# Must be imported by configuration.nix
# See: https://nixos.wiki/wiki/Nvidia

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.hardware.nvidiaGpu.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enabling Nvidia GPU configuration";
    };
  };

  config = lib.mkIf config.curios.hardware.nvidiaGpu.enable {
    # Use the systemd-boot EFI boot loader.
    boot = {
      # Ban CPU integrated GPU
      blacklistedKernelModules = [ "i915" "nouveau" ];
    };

    # Nvidia GPU
    # Enable OpenGL
    hardware.graphics = {
      enable = lib.mkDefault true;
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.enable = lib.mkDefault true;
    services.xserver.videoDrivers = ["nvidia"];

    # Allow unfree packages
    nixpkgs.config.allowUnfree = lib.mkForce true;
    nixpkgs.config.nvidia.acceptLicense = true;

    hardware.nvidia = {
      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # For RTX 50, 40, 30, 20, GTX 16 series and set open to true !
      package = config.boot.kernelPackages.nvidiaPackages.production;
      # For GeForce 800, 900 and 10 series
      #package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
    };
  };
}
