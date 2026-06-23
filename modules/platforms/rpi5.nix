# For Raspberry PI 5 platform
# All other platforms and file-system configurations should be disabled.
# Download NixOS ISO file from: https://hydra.nixos.org/job/nixos/release-26.05/nixos.sd_image.aarch64-linux
# Burn the zst image with caligula with:
# caligula burn -z zst nixos-image-sd-card-26.05.2462.e8210c649915-aarch64-linux.img.zst
# Boot from the SD card.
# If needed, change keyboard layout with:
# sudo loadkeys us
# Then:
# cd /tmp
# nix-shell -p git
# git clone https://github.com/CuriosLabs/CuriOS.git
# cd CuriOS/
# nix-shell shell-rpi.nix --run "sudo ./curios-install --rpi5"

let
  nixos-hardware = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/875776f0252fcb8618bb948640a0d1f7a5b362be.tar.gz";
    sha256 = "0z7mhrdr2pwh6a5srjib3s8x3ccn54bmafb4021ccvha2x06fjzw";
  };
in { config, pkgs, lib, ... }:

{
  imports = [ "${nixos-hardware}/raspberry-pi/5" ];

  # Declare options
  options = {
    curios.platform.rpi5.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "REQUIRED config on Raspberry PI 5 platform ONLY.";
    };
  };

  config = lib.mkIf config.curios.platform.rpi5.enable {
    boot = {
      kernelParams = [
        "snd_bcm2835.enable_hdmi=1"
        "snd_bcm2835.enable_headphones=1"
        "usbhid.mousepoll=8"
      ];
      initrd.availableKernelModules = lib.mkDefault
        (config.boot.initrd.availableKernelModules
          ++ [ "xhci_pci" "usbhid" "usb_storage" "vc4" ]);
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
      # nixos-hardware already sets deviceTree.filter
      deviceTree.enable = lib.mkDefault true;
      # For Wifi module firmware
      enableRedistributableFirmware = true;
    };

    console.enable = lib.mkForce false;
    environment.systemPackages = with pkgs; [
      libraspberrypi
      raspberrypi-eeprom
    ];

    services.xserver = { enable = lib.mkDefault true; };
  };
}
