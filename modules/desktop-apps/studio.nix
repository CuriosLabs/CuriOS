# Video editing related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps.studio.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Enable desktop apps related to video/photo edition: obs-studio, audacity, DaVinci Resolve, Darktable.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.studio.enable {
    # OBS
    programs.obs-studio = { enable = true; };
    environment.systemPackages = with pkgs; [ audacity davinci-resolve darktable ];
  };
}
