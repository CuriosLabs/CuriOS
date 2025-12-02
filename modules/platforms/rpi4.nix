# For Raspberry PI 4 platform
# All other platforms and file-system configurations should be disabled.
# Download NixOS ISO file from: https://hydra.nixos.org/job/nixos/release-25.05/nixos.sd_image.aarch64-linux

{ config, pkgs, lib, ... }:

{
  # Declare options
  options = {
    curios.platform.rpi4.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Raspberry PI 4 configuration";
    };
  };

  config = lib.mkIf config.curios.platform.rpi4.enable {
    boot = {
      kernelPackages = lib.mkDefault pkgs.linuxKernel.packages.linux_rpi4;
      kernelParams = [
        "snd_bcm2835.enable_hdmi=1"
        "snd_bcm2835.enable_headphones=1"
        "usbhid.mousepoll=8"
      ];
      initrd.availableKernelModules =
        [ "xhci_pci" "usbhid" "usb_storage" "vc4" ];
      loader = {
        grub.enable = lib.mkDefault false;
        generic-extlinux-compatible.enable = lib.mkDefault true;
      };
      tmp.cleanOnBoot = true;
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    };

    swapDevices = [ ];

    networking = {
      # Prevent host becoming unreachable on wifi after some time.
      networkmanager.wifi.powersave = lib.mkDefault false;
    };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    hardware = {
      deviceTree.enable = lib.mkDefault true;
      deviceTree.filter = lib.mkDefault "bcm2711-rpi-*.dtb"; # "*rpi-4-*.dtb";
      # For Wifi module firmware
      enableRedistributableFirmware = true;
      #raspberry-pi."4".fkms-3d.enable = true;
    };

    console.enable = false;
    environment.systemPackages = with pkgs; [
      libraspberrypi
      raspberrypi-eeprom
    ];

    services.xserver = {
      enable = lib.mkDefault true;
      #displayManager.lightdm.enable = true;
      #desktopManager.gnome.enable = true;
    };
  };
}
