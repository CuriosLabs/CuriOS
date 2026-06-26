# For Raspberry PI 4 platform
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
# nix-shell shell-rpi.nix --run "sudo ./curios-install --rpi4"

let
  nixos-hardware = builtins.fetchTarball {
    url =
      "https://github.com/NixOS/nixos-hardware/archive/603d3afd1b6145bd66e97ae38a34d91c95df70cf.tar.gz";
    sha256 = "1qhzdprp5nshf98gd3afm8j0241m9gbaxwcf3ynrmvls9y4wzyyc";
  };
in { config, pkgs, lib, ... }:

{
  imports = [ "${nixos-hardware}/raspberry-pi/4" ];

  # Declare options
  options = { };

  config = lib.mkIf config.curios.platform.rpi4.enable {
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
      #raspberry-pi."4".fkms-3d.enable = true;
    };

    console.enable = lib.mkForce false;
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
