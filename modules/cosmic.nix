# COSMIC desktop environment

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.cosmic.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "REQUIRED enable the COSMIC desktop environment.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.cosmic.enable {
    # Cosmic Desktop Env
    services.desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true;
    };
    services.displayManager.cosmic-greeter = {
      enable = true;
      package = pkgs.cosmic-greeter;
    };

    environment = {
      cosmic.excludePackages = [ pkgs.cosmic-term ];
      systemPackages = with pkgs; [
        jq
        lld
        lswt
        isocodes
        xdg-utils
        xdg-user-dirs
      ];
      # TODO: link "${pkgs.isocodes}/share/iso-codes/" to /usr/share/iso-codes/ - XDG_DATA_DIRS ??

      # Env variables
      sessionVariables = {
        # Hint Electron apps to use Wayland
        NIXOS_OZONE_WL = "1";
      };

      # XDG user directories defaults
      etc."xdg/user-dirs.defaults".text = ''
        DESKTOP=Desktop
        DOWNLOAD=Downloads
        TEMPLATES=Templates
        PUBLICSHARE=Public
        DOCUMENTS=Documents
        MUSIC=Music
        PICTURES=Pictures
        VIDEOS=Videos
        PROJECTS=Projects
      '';
    };

    # systemd user services
    systemd.user.services.xdg-user-dirs-update = {
      enable = true;
      description = "Update XDG user directories";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = [ "/run/current-system/sw/bin/xdg-user-dirs-update" ];
        #  "${pkgs.coreutils}/bin/mkdir -p %h/Projects"
        #  "${pkgs.bash}/bin/bash -c 'mkdir -p %h/.config && if [ -f %h/.config/user-dirs.dirs ]; then if ! grep -q XDG_PROJECTS_DIR %h/.config/user-dirs.dirs; then echo \"XDG_PROJECTS_DIR=\\\"\\$HOME/Projects\\\"\" >> %h/.config/user-dirs.dirs; fi; fi'"
        #];
      };
    };

    xdg = {
      icons.enable = true;
      mime.enable = true;
    };
  };
}
