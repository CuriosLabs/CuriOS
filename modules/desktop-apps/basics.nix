# Basic desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps = {
      basics.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "CuriOS minimum desktop apps.";
      };
      appImage.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enabling Linux AppImage.";
      };
      vpn.proton.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "ProtonVPN GUI";
      };
      vpn.tailscale.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "TailScale VPN";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.basics.enable {
    environment.systemPackages = [
      pkgs.caligula

      # Alacritty terminal
      pkgs.alacritty
      # alacritty-theme

      # 3rd party apps
      pkgs.bitwarden-desktop
      pkgs.brave
      pkgs.easyeffects
      pkgs.ffmpeg_6-full
      pkgs.gimp3-with-plugins
      pkgs.gparted
      pkgs.libsecret
      pkgs.polkit_gnome
      pkgs.signal-desktop
      pkgs.vlc
      pkgs.yubioath-flutter

      # webapp
      (import ./webapp-whatsapp.nix)
    ]
    ++ lib.optionals config.curios.desktop.apps.vpn.proton.enable [
      pkgs.protonvpn-gui
    ]
    ++ lib.optionals config.curios.desktop.apps.vpn.tailscale.enable [
      pkgs.tailscale
    ];

    # Enabling PCSC-lite for Yubikey
    services.pcscd.enable = true;

    # systemd
    systemd = {
      user = {
        # Start polkit_gnome as a systemd service
        services.polkit-gnome-authentication-agent-1 = {
          description = "polkit-gnome-authentication-agent-1";
          wantedBy = [ "graphical-session.target" ];
          wants = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
      };
    };

    # Enabling Linux AppImage
    programs.appimage.enable = lib.mkDefault config.curios.desktop.apps.appImage.enable;
    programs.appimage.binfmt = lib.mkDefault config.curios.desktop.apps.appImage.enable;
  };
}
