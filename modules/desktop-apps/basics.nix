# Basic desktop applications.

{ config, lib, pkgs, ... }:

let
  lmstudioApp = import ./desktop-lm-studio.nix { inherit pkgs lib; };
  lmstudioBionicApp =
    import ./desktop-lm-studio-bionic.nix { inherit pkgs lib; };
  curiosDocsWebapp = import ./webapp-curios-docs.nix { inherit pkgs lib; };
  voxtypeHasGpu =
    (lib.attrByPath [ "curios" "hardware" "nvidiaGpu" "enable" ] false config)
    || (lib.attrByPath [ "curios" "hardware" "amdGpu" "enable" ] false config);
  voxtypePkg = if voxtypeHasGpu then pkgs.voxtype-vulkan else pkgs.voxtype;
  voxtypeSetupScript = pkgs.writeShellApplication {
    name = "voxtype-setup";
    runtimeInputs = [ pkgs.curl voxtypePkg ];
    text = ''
      mkdir -p "$HOME/.config/voxtype"
      rm -f "$HOME/.config/voxtype/config.toml"
      cp /etc/voxtype/config.toml "$HOME/.config/voxtype/config.toml"
      chmod u+w "$HOME/.config/voxtype/config.toml"
      /run/current-system/sw/bin/voxtype setup --download
    '';
  };
in {
  # Declare options
  options = {
    curios.desktop = {
      basics.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "REQUIRED - CuriOS desktop applications: Brave, Bitwarden, VLC, Yubikey...";
      };
      appImage.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enabling Linux AppImage support.";
      };
      browser = {
        brave = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Brave privacy-oriented Web Browser";
          };
          remoteDebuggingAllowed = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description =
              "Turning on this setting allows external apps to request full control of this browser. Used by AI agents.";
          };
        };
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
          default = false;
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
        lmstudio = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "LM Studio - Local AI on your computer.";
          };
          bionic = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "LM Studio Bionic - Local AI agent for open models.";
          };
        };
        mistral.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Mistral LeChat web app.";
        };
        windsurf.enable = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "DEPRECATED";
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
          default = false;
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
        voxtype = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description =
              "Voxtype local voice-to-text (Vulkan when AMD/NVIDIA GPU is enabled). After enabling, download the selected Whisper model.";
          };
          audiofeedback = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description =
                "Voxtype audio feedback when recording starts and stops.";
            };
            volume = lib.mkOption {
              type = lib.types.numbers.between 0.0 1.0;
              default = 0.3;
              description = "Voxtype audio feedback volume (0.0 to 1.0).";
            };
          };
          model = lib.mkOption {
            type = lib.types.enum [ "tiny" "base" "medium" "large-v3" ];
            default = "base";
            description = "Whisper model (multilingual).";
          };
          notifications = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description =
              "Voxtype notification when recording starts and stops.";
          };
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.basics.enable {
    # bitwarden-desktop on NixOS 26.05 pins electron_39 which is marked EOL.
    # TODO: remove when bitwarden-dekstop pin electron>=40
    nixpkgs.config.permittedInsecurePackages =
      lib.mkIf config.curios.desktop.utility.bitwarden.enable
      [ "electron-39.8.10" ];

    # Brave ANGLE libs ship without RUNPATH. GPU sandbox drops LD_LIBRARY_PATH,
    # so ANGLE cannot dlopen libEGL.so.1 / libvulkan.so.1 → WebGL disabled with
    # "GPU access is disabled due to frequent crashes". Same fix as nixpkgs
    # Chromium: patchelf RPATH onto ANGLE + replace bundled vulkan-loader.
    nixpkgs.overlays = lib.mkIf config.curios.desktop.browser.brave.enable [
      (final: prev: {
        brave = prev.brave.overrideAttrs (old: {
          postFixup = (old.postFixup or "") + ''
            braveLib=$out/opt/brave.com/brave
            glRpath=${lib.makeLibraryPath [ final.libGL final.vulkan-loader ]}
            for f in "$braveLib/brave" "$braveLib/libEGL.so" "$braveLib/libGLESv2.so"; do
              if [ -f "$f" ]; then
                oldRpath=$(patchelf --print-rpath "$f" 2>/dev/null || true)
                if [ -n "$oldRpath" ]; then
                  patchelf --set-rpath "$glRpath:$oldRpath" "$f"
                else
                  patchelf --set-rpath "$glRpath" "$f"
                fi
              fi
            done
            if [ -e "$braveLib/libvulkan.so.1" ]; then
              rm -f "$braveLib/libvulkan.so.1"
              ln -s ${
                lib.getLib final.vulkan-loader
              }/lib/libvulkan.so.1 "$braveLib/libvulkan.so.1"
            fi
          '';
        });
      })
    ];

    environment = {
      systemPackages = [
        pkgs.caligula
        curiosDocsWebapp

        # alacritty-theme
        pkgs.tmux

        # 3rd party apps
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
        pkgs.proton-vpn
        (lib.mkIf config.curios.desktop.vpn.proton.autoStart
          (pkgs.makeAutostartItem {
            name = "proton.vpn.app.gtk";
            package = pkgs.proton-vpn;
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
        [ (import ./webapp-grok.nix) ] ++ lib.optionals
        (config.curios.desktop.ai.lmstudio.enable
          && config.curios.platform.amd64.enable) [ lmstudioApp ]
        ++ lib.optionals (config.curios.desktop.ai.lmstudio.bionic
          && config.curios.platform.amd64.enable) [ lmstudioBionicApp ]
        ++ lib.optionals config.curios.desktop.ai.mistral.enable
        [ (import ./webapp-mistral.nix) ]
        ++ lib.optionals config.curios.desktop.browser.brave.enable
        [ pkgs.brave ]
        ++ lib.optionals config.curios.desktop.browser.chromium.enable
        [ pkgs.ungoogled-chromium ]
        ++ lib.optionals config.curios.desktop.browser.firefox.enable
        [ pkgs.firefox ]
        ++ lib.optionals config.curios.desktop.browser.librewolf.enable
        [ pkgs.librewolf ]
        ++ lib.optionals config.curios.desktop.browser.vivaldi.enable
        [ pkgs.vivaldi ] ++ lib.optionals
        (config.curios.desktop.chat.discord.enable
          && config.curios.platform.amd64.enable) [ pkgs.discord ]
        ++ lib.optionals config.curios.desktop.chat.signal.enable
        [ pkgs.signal-desktop ] ++ lib.optionals
        (config.curios.desktop.chat.teamspeak.enable
          && config.curios.platform.amd64.enable) [ pkgs.teamspeak6-client ]
        ++ lib.optionals config.curios.desktop.chat.whatsapp.enable
        [ (import ./webapp-whatsapp.nix) ]
        ++ lib.optionals config.curios.desktop.music.strawberry.enable
        [ pkgs.strawberry ] ++ lib.optionals
        (config.curios.desktop.music.spotify.enable
          && config.curios.platform.amd64.enable) [ pkgs.spotify ]
        ++ lib.optionals config.curios.desktop.utility.bitwarden.enable
        [ pkgs.bitwarden-desktop ]
        ++ lib.optionals config.curios.desktop.utility.keepassxc.enable
        [ pkgs.keepassxc ]
        ++ lib.optionals config.curios.desktop.utility.flameshot.enable
        [ pkgs.flameshot ]
        ++ lib.optionals config.curios.desktop.utility.voxtype.enable
        [ voxtypePkg ];

      # Brave group policy examples
      # See: https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy
      # https://chromeenterprise.google/policies/
      etc = {
        "brave/policies/managed/settings.json".text = ''
          {
            "BraveRewardsDisabled": true,
            "BraveWalletDisabled": true
          }
        '';
        "brave/policies/managed/inspect.json" =
          lib.mkIf config.curios.desktop.browser.brave.remoteDebuggingAllowed {
            text = ''
              {
                "RemoteDebuggingAllowed": true
              }
            '';
          };
        "voxtype/config.toml" =
          lib.mkIf config.curios.desktop.utility.voxtype.enable {
            text = ''
              state_file = "auto"

              [hotkey]
              enabled = false
              mode = "toggle"

              [audio]
              device = "default"
              sample_rate = 16000
              max_duration_secs = 60

              [audio.feedback]
              enabled = ${
                lib.boolToString
                config.curios.desktop.utility.voxtype.audiofeedback.enable
              }
              theme = "default"
              volume = ${
                lib.toString
                config.curios.desktop.utility.voxtype.audiofeedback.volume
              }

              [whisper]
              model = "${config.curios.desktop.utility.voxtype.model}"
              language = "auto"
              translate = false
              on_demand_loading = false
              # context_window_optimization = true

              [output]
              mode = "type"
              fallback_to_clipboard = true
              type_delay_ms = 0
              pre_type_delay_ms = 100

              [output.notification]
              on_recording_start = ${
                lib.boolToString
                config.curios.desktop.utility.voxtype.notifications
              }
              on_recording_stop = ${
                lib.boolToString
                config.curios.desktop.utility.voxtype.notifications
              }
              on_transcription = false
            '';
          };
      };
      # Add Bitwarden browser extension to Brave
      # See: https://chromeenterprise.google/policies/#ExtensionSettings
      #etc."brave/policies/managed/settings.json".text = ''
      #  {
      #    "BraveRewardsDisabled": true,
      #    "BraveWalletDisabled": true,
      #    "ExtensionSettings": {
      #      "nngceckbapebfimnlniiiahkandclblb": {
      #        "installation_mode": "force_installed",
      #        "update_url": "https://clients2.google.com/service/update2/crx"
      #      }
      #    },
      #    "PasswordManagerEnabled": false
      #  }
      #'';
    };

    services = {
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
        services.voxtype =
          lib.mkIf config.curios.desktop.utility.voxtype.enable {
            description = "Voxtype voice-to-text daemon";
            wantedBy = [ "graphical-session.target" ];
            wants = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            path = [ pkgs.curl ];
            serviceConfig = {
              Type = "simple";
              ExecStartPre = "${voxtypeSetupScript}/bin/voxtype-setup";
              ExecStart = "${voxtypePkg}/bin/voxtype daemon";
              Restart = "on-failure";
              RestartSec = 5;
              TimeoutStartSec = 600;
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
