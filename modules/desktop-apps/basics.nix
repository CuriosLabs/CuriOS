# Basic desktop applications.

{ config, lib, pkgs, ... }:

let
  lmstudioApp = import ./desktop-lm-studio.nix { inherit pkgs lib; };
  curiosDocsWebapp = import ./webapp-curios-docs.nix { inherit pkgs lib; };
in {
  # Declare options
  options = {
    curios.desktop = {
      basics.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "REQUIRED CuriOS desktop applications: Alacritty, Brave, Bitwarden, VLC, Yubikey...";
      };
      appImage.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enabling Linux AppImage support.";
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
        tailscale = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "TailScale VPN";
          };
          useRoutingFeatures = lib.mkOption {
            type = lib.types.enum [ "none" "client" "server" "both" ];
            default = "none";
            example = "server";
          };
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
          default = true;
          description = "Cursor AI-assisted IDE - desktop app and CLI.";
        };
        gemini.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Google Gemini web app.";
        };
        grok.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Grok web app.";
        };
        lmstudio.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "LM Studio - Local AI on your computer.";
        };
        mistral.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Mistral LeChat web app.";
        };
        windsurf.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Windsurf AI-assisted IDE - desktop app.";
        };
      };
      chat = {
        discord.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Discord desktop app.";
        };
        signal.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Signal.org desktop app.";
        };
        teamspeak.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "TeamSpeak6 desktop app.";
        };
        whatsapp.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "WhatsApp web app.";
        };
      };
      music = {
        strawberry.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Music player and music collection organizer.";
        };
        spotify.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Play music from the Spotify music service.";
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
  config = lib.mkIf config.curios.desktop.basics.enable {
    environment = {
      systemPackages = [
        pkgs.caligula
        curiosDocsWebapp

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
      ] ++ lib.optionals config.curios.desktop.vpn.proton.enable [
        pkgs.protonvpn-gui
        (lib.mkIf config.curios.desktop.vpn.proton.autoStart
          (pkgs.makeAutostartItem {
            name = "proton.vpn.app.gtk";
            package = pkgs.protonvpn-gui;
            appendExtraArgs = [ "--start-minimized" ];
          }))
      ] ++ lib.optionals config.curios.desktop.ai.chatgpt.enable
        [ (import ./webapp-chatgpt.nix) ]
        ++ lib.optionals config.curios.desktop.ai.claude.enable
        [ (import ./webapp-claude.nix) ]
        ++ lib.optionals config.curios.desktop.ai.cursor.enable [
          pkgs.cursor-cli
          pkgs.code-cursor
        ] ++ lib.optionals config.curios.desktop.ai.gemini.enable
        [ (import ./webapp-gemini.nix) ]
        ++ lib.optionals config.curios.desktop.ai.grok.enable
        [ (import ./webapp-grok.nix) ]
        ++ lib.optionals config.curios.desktop.ai.lmstudio.enable
        [ lmstudioApp ] ++ lib.optionals config.curios.desktop.ai.mistral.enable
        [ (import ./webapp-mistral.nix) ]
        ++ lib.optionals config.curios.desktop.ai.windsurf.enable
        [ pkgs.windsurf ]
        ++ lib.optionals config.curios.desktop.browser.chromium.enable
        [ pkgs.ungoogled-chromium ]
        ++ lib.optionals config.curios.desktop.browser.firefox.enable
        [ pkgs.firefox ]
        ++ lib.optionals config.curios.desktop.browser.librewolf.enable
        [ pkgs.librewolf ]
        ++ lib.optionals config.curios.desktop.browser.vivaldi.enable
        [ pkgs.vivaldi ]
        ++ lib.optionals config.curios.desktop.chat.discord.enable
        [ pkgs.discord ]
        ++ lib.optionals config.curios.desktop.chat.signal.enable
        [ pkgs.signal-desktop ]
        ++ lib.optionals config.curios.desktop.chat.teamspeak.enable
        [ pkgs.teamspeak6-client ]
        ++ lib.optionals config.curios.desktop.chat.whatsapp.enable
        [ (import ./webapp-whatsapp.nix) ]
        ++ lib.optionals config.curios.desktop.music.strawberry.enable
        [ pkgs.strawberry ]
        ++ lib.optionals config.curios.desktop.music.spotify.enable
        [ pkgs.spotify ]
        ++ lib.optionals config.curios.desktop.utility.bitwarden.enable
        [ pkgs.bitwarden-desktop ]
        ++ lib.optionals config.curios.desktop.utility.keepassxc.enable
        [ pkgs.keepassxc ]
        ++ lib.optionals config.curios.desktop.utility.flameshot.enable
        [ pkgs.flameshot ];

      # Brave group policy example
      # See: https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
      # https://chromeenterprise.google/policies/
      etc."brave/policies/managed/settings.json".text = ''
        {
          "BraveRewardsDisabled": true,
          "BraveWalletDisabled": true
        }
      '';
      # Add Bitwarden browser extension to Brave
      # See: https://chromeenterprise.google/policies/#ExtensionSettings
      etc."brave/policies/managed/managed_preferences.json".text = ''
        {
          "ExtensionSettings": {
            "nngceckbapebfimnlniiiahkandclblb": {
              "installation_mode": "force_installed",
              "update_url": "https://clients2.google.com/service/update2/crx"
            }
          },
          "PasswordManagerEnabled": false
        }
      '';
    };

    services = {
      # Enabling PCSC-lite for Yubikey
      pcscd.enable = true;

      # Tailscale VPN - See https://wiki.nixos.org/wiki/Tailscale
      # Configure it it with `sudo tailscale up`
      # To add more options, see: https://search.nixos.org/options?show=services.tailscale
      # To allow current user to manage tailscale daemon: `sudo tailscale set --operator=$USER`
      # To launch the systray app on startup: `tailscale configure systray --enable-startup=systemd`
      tailscale = {
        enable = lib.mkDefault config.curios.desktop.vpn.tailscale.enable;
        permitCertUid = null;
        useRoutingFeatures =
          lib.mkDefault config.curios.desktop.vpn.tailscale.useRoutingFeatures;
      };
      # Mullvad VPN
      mullvad-vpn = {
        enable = lib.mkDefault config.curios.desktop.vpn.mullvad.enable;
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
      appimage.enable = lib.mkDefault config.curios.desktop.appImage.enable;
      appimage.binfmt = lib.mkDefault config.curios.desktop.appImage.enable;
      localsend = {
        enable = lib.mkDefault config.curios.desktop.utility.localsend.enable;
      };
    };
  };
}
