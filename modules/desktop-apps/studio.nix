# Video editing related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.studio = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Video/Photo edition tools: OBS, Audacity, Darktable.";
      };
      davinci-resolve.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "DaVinci Resolve Free version";
      };
      davinci-resolve-studio.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "DaVinci Resolve Studio version (buy online)";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.studio.enable {
    # OBS
    programs.obs-studio = { enable = true; };
    environment.systemPackages = [ pkgs.audacity pkgs.darktable ]
      ++ lib.optionals config.curios.desktop.studio.davinci-resolve.enable
      [ pkgs.davinci-resolve ] ++ lib.optionals
      config.curios.desktop.studio.davinci-resolve-studio.enable
      [ pkgs.davinci-resolve-studio ];
  };
}
