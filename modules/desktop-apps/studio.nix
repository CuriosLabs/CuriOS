# Video editing related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.studio = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Video/Photo applications - Gimp, VLC.";
      };
      audacity.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Sound editor application.";
      };
      darktable.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Darktable darkroom for photographers.";
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
      inkscape.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Inkscape is a feature-rich vector graphics editor for SVG files.";
      };
      krita.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Krita is a professional free and open source painting.";
      };
      mpv.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "mpv - A free, open source media player for the command line.";
      };
      obs-studio.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "OBS Studio for video recording and live streaming.";
      };
      rawtherapee.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "RAW converter and digital photo processing application.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.studio.enable {
    # OBS
    programs.obs-studio = {
      enable = lib.mkDefault config.curios.desktop.studio.obs-studio.enable;
    };
    environment.systemPackages = [ pkgs.gimp3-with-plugins pkgs.vlc ]
      ++ lib.optionals config.curios.desktop.studio.audacity.enable
      [ pkgs.audacity ]
      ++ lib.optionals config.curios.desktop.studio.darktable.enable
      [ pkgs.darktable ] ++ lib.optionals
      (config.curios.desktop.studio.davinci-resolve.enable
        && config.curios.platform.amd64.enable) [ pkgs.davinci-resolve ]
      ++ lib.optionals
      (config.curios.desktop.studio.davinci-resolve-studio.enable
        && config.curios.platform.amd64.enable) [ pkgs.davinci-resolve-studio ]
      ++ lib.optionals config.curios.desktop.studio.inkscape.enable
      [ pkgs.inkscape-with-extensions ]
      ++ lib.optionals config.curios.desktop.studio.krita.enable [ pkgs.krita ]
      ++ lib.optionals config.curios.desktop.studio.mpv.enable [ pkgs.mpv ]
      ++ lib.optionals config.curios.desktop.studio.rawtherapee.enable
      [ pkgs.rawtherapee ];
  };
}
