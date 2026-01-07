# Basic desktop apps.

{ config, lib, pkgs, ... }:

let lmstudioApp = import ./desktop-lm-studio.nix { inherit pkgs lib; };
in {
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
        proton = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "ProtonVPN GUI";
          };
          # App autostart example: It copy the desktop file from the package $package/share/applications/$srcPrefix$name.desktop
          # to $out/etc/xdg/autostart/$name.desktop so the app will be launched on user graphical session opening.
          # See: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/make-startupitem/default.nix
          autoStart = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description =
              "Whether ProtonVPN should started automatically on user desktop login.";
            example = false;
          };
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
        cursor.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "AI-assisted IDE - desktop app and CLI.";
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
        lmstudio.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "LM Studio - Local AI on your computer.";
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
      utility = {
        bitwarden.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Bitwarden password manager.";
        };
        flameshot.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Flameshot screenshot tool.";
        };
        keepassxc.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "KeePassXC password manager.";
        };
        localsend.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description =
            "LocalSend - Cross-platform file sharing on your local network.";
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
      pkgs.brave
      pkgs.easyeffects
      pkgs.ffmpeg_6-full
      pkgs.gimp3-with-plugins
      pkgs.gparted
      pkgs.imagemagick
      pkgs.libsecret
      pkgs.polkit_gnome
      pkgs.procs
      pkgs.tldr
      pkgs.vlc
      pkgs.yubioath-flutter
    ] ++ lib.optionals config.curios.desktop.apps.vpn.proton.enable [
      pkgs.protonvpn-gui
      (lib.mkIf config.curios.desktop.apps.vpn.proton.autoStart
        (pkgs.makeAutostartItem {
          name = "proton.vpn.app.gtk";
          package = pkgs.protonvpn-gui;
          appendExtraArgs = [ "--start-minimized" ];
        }))
    ] ++ lib.optionals config.curios.desktop.apps.ai.chatgpt.enable
      [ (import ./webapp-chatgpt.nix) ]
      ++ lib.optionals config.curios.desktop.apps.ai.claude.enable
      [ (import ./webapp-claude.nix) ]
      ++ lib.optionals config.curios.desktop.apps.ai.cursor.enable [
        pkgs.cursor-cli
        pkgs.code-cursor
      ] ++ lib.optionals config.curios.desktop.apps.ai.gemini.enable [
        pkgs.gemini-cli
        (import ./desktop-gemini.nix)
      ] ++ lib.optionals config.curios.desktop.apps.ai.grok.enable
      [ (import ./webapp-grok.nix) ]
      ++ lib.optionals config.curios.desktop.apps.ai.lmstudio.enable
      [ lmstudioApp ]
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
      [ (import ./webapp-whatsapp.nix) ]
      ++ lib.optionals config.curios.desktop.apps.utility.bitwarden.enable
      [ pkgs.bitwarden-desktop ]
      ++ lib.optionals config.curios.desktop.apps.utility.keepassxc.enable
      [ pkgs.keepassxc ]
      ++ lib.optionals config.curios.desktop.apps.utility.flameshot.enable
      [ pkgs.flameshot ];

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

    programs = {
      # Enabling Linux AppImage
      appimage.enable =
        lib.mkDefault config.curios.desktop.apps.appImage.enable;
      appimage.binfmt =
        lib.mkDefault config.curios.desktop.apps.appImage.enable;
      localsend = {
        enable =
          lib.mkDefault config.curios.desktop.apps.utility.localsend.enable;
      };
    };
  };
}
