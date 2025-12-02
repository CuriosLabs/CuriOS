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
      browser = {
        chromium.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Ungoogled Chromium Web Browser";
        };
        firefox.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Mozilla Firefox Web Browser";
        };
        librewolf.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Fork of Firefox Web Browser";
        };
        vivaldi.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Vivaldi Web Browser";
        };
      };
      vpn = {
        proton.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "ProtonVPN GUI";
        };
        tailscale.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "TailScale VPN";
        };
        mullvad.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Mullvad VPN GUI";
        };
      };
      ai = {
        chatgpt.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "ChatGPT web app.";
        };
        claude.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Claude web app.";
        };
        gemini.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Google Gemini CLI.";
        };
        grok.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Grok web app.";
        };
        mistral.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Mistral LeChat web app.";
        };
      };
      chat = {
        signal.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Signal.org desktop app.";
        };
        whatsapp.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "WhatsApp web app.";
        };
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
      pkgs.vlc
      pkgs.yubioath-flutter
    ] ++ lib.optionals config.curios.desktop.apps.vpn.proton.enable
      [ pkgs.protonvpn-gui ]
      ++ lib.optionals config.curios.desktop.apps.ai.chatgpt.enable
      [ (import ./webapp-chatgpt.nix) ]
      ++ lib.optionals config.curios.desktop.apps.ai.claude.enable
      [ (import ./webapp-claude.nix) ]
      ++ lib.optionals config.curios.desktop.apps.ai.gemini.enable [
        pkgs.gemini-cli
        (import ./desktop-gemini.nix)
      ] ++ lib.optionals config.curios.desktop.apps.ai.grok.enable
      [ (import ./webapp-grok.nix) ]
      ++ lib.optionals config.curios.desktop.apps.ai.mistral.enable
      [ (import ./webapp-mistral.nix) ]
      ++ lib.optionals config.curios.desktop.apps.browser.chromium.enable
      [ pkgs.ungoogled-chromium ]
      ++ lib.optionals config.curios.desktop.apps.browser.firefox.enable
      [ pkgs.firefox ]
      ++ lib.optionals config.curios.desktop.apps.browser.librewolf.enable
      [ pkgs.librewolf ]
      ++ lib.optionals config.curios.desktop.apps.browser.vivaldi.enable
      [ pkgs.vivaldi ]
      ++ lib.optionals config.curios.desktop.apps.chat.signal.enable
      [ pkgs.signal-desktop ]
      ++ lib.optionals config.curios.desktop.apps.chat.whatsapp.enable
      [ (import ./webapp-whatsapp.nix) ];

    services = {
      # Enabling PCSC-lite for Yubikey
      pcscd.enable = true;

      # Tailscale VPN - See https://wiki.nixos.org/wiki/Tailscale
      tailscale = {
        enable = lib.mkDefault config.curios.desktop.apps.vpn.tailscale.enable;
        permitCertUid = null;
        useRoutingFeatures = "none";
      };
      # Mullvad VPN
      mullvad-vpn = {
        enable = lib.mkDefault config.curios.desktop.apps.vpn.mullvad.enable;
        # pkgs.mullvad-vpn for CLI and GUI - pkgs.mullvad for only CLI
        package = pkgs.mullvad-vpn;
      };
    };

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
            ExecStart =
              "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
      };
    };

    # Enabling Linux AppImage
    programs.appimage.enable =
      lib.mkDefault config.curios.desktop.apps.appImage.enable;
    programs.appimage.binfmt =
      lib.mkDefault config.curios.desktop.apps.appImage.enable;
  };
}
