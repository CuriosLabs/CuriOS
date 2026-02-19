# Video editing related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.studio.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Applications related to video/photo edition: OBS, Audacity, DaVinci Resolve, Darktable.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.studio.enable {
    # OBS
    programs.obs-studio = { enable = true; };
    environment.systemPackages = with pkgs; [
      audacity
      davinci-resolve
      darktable
    ];
  };
}
