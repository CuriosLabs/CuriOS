# Video editing related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktopApps.studio.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Enable desktop applications related to video/photo edition: obs-studio, audacity, DaVinci Resolve, Darktable.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktopApps.studio.enable {
    # OBS
    programs.obs-studio = { enable = true; };
    environment.systemPackages = with pkgs; [
      audacity
      davinci-resolve
      darktable
    ];
  };
}
