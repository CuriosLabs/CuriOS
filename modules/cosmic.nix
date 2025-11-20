# COSMIC desktop environment

{ config, lib, pkgs, ... }:
{
  # Declare options
  options = {
    curios.desktop.cosmic.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the COSMIC desktop environment.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.cosmic.enable {
    # Cosmic Desktop Env
    services.desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true;
    };
    services.displayManager.cosmic-greeter = {
      enable = true;
      package = pkgs.cosmic-greeter;
    };

    environment.systemPackages = with pkgs; [
      jq
      lld
      lswt
      isocodes
      xdg-utils
    ];
    # TODO: link "${pkgs.isocodes}/share/iso-codes/" to /usr/share/iso-codes/ - XDG_DATA_DIRS ??

    # Env variables
    environment.sessionVariables = {
      # Hint Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";
    };

    xdg = {
      icons.enable = true;
      mime.enable = true;
    };
  };
}
