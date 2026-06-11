# Security options (U2F/FIDO2, YubiKey, etc.)

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.security = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED - CuriOS security keys options.";
      };

      u2f = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable U2F/FIDO2 authentication with pam_u2f (YubiKey, Nitrokey, etc.).";
        };

        appid = lib.mkOption {
          type = lib.types.str;
          default = "curios";
          example = "curios";
          description = "AppID used by pam_u2f.";
        };

        lockOnRemove = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Automatically lock all user sessions when a YubiKey is physically removed.";
        };

        origin = lib.mkOption {
          type = lib.types.str;
          default = "curios";
          example = "curios";
          description = "Origin used by pam_u2f.";
        };
      };

      keyringProvider = lib.mkOption {
        type = lib.types.enum [ "gnome-keyring" "keepassxc" ];
        default = "gnome-keyring";
        description = "EXPERIMENTAL - Select the Secret Service (freedesktop.org) provider used while U2F is active.";
      };

      # LUKS disk encryption with FIDO2 (YubiKey etc.) is configured here
      # but applied in modules/filesystems/filesystems-luks-v2.nix so that
      # the core LUKS module stays focused on filesystem layout.
      luksFido2 = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable FIDO2 key support (YubiKey, etc.) for unlocking the LUKS disk volume during boot.";
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.security.enable {
    programs = {
      ssh = {
        agentPKCS11Whitelist = "${pkgs.opensc}/lib/opensc-pkcs11.so";
        # SSH start-agent - not compatible with gnupg.agent SSH - Cosmic already set services.gnome.gnome-keyring.enable to true - cannot run both.
        startAgent = lib.mkDefault false;
      };
    };

    security = {
      # /etc/login.defs additionnal settings
      loginDefs.settings = {
        LOGIN_RETRIES = 3;
        LOGIN_TIMEOUT = 60;
      };

      pam = {
        u2f = {
          # U2F are sufficient replacements to passwords.
          control = "sufficient";
          enable = lib.mkDefault config.curios.security.u2f.enable;
          settings = {
            cue = true;
            interactive = true;
            nouserok = true; # Do not fail if the user has no U2F key configured
            origin = config.curios.security.u2f.origin;
            appid = config.curios.security.u2f.appid;
          };
        };

        services = {
          cosmic-greeter.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
          greetd.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
          login.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
          sudo.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
        };
      };

      rtkit.enable = lib.mkDefault true; # realtime scheduling priority for pipewire.

      # Show password feedback for sudo command.
      sudo.extraConfig = "Defaults pwfeedback";
    };

    services = {
      # Enabling PCSC-lite for Yubikey
      pcscd.enable = true;

      # Lock screen when YubiKey is removed (physical security feature)
      udev.extraRules = lib.mkIf config.curios.security.u2f.lockOnRemove ''
        ACTION=="remove",\
          SUBSYSTEM=="usb",\
          ENV{ID_VENDOR_ID}=="1050",\
          ENV{ID_VENDOR}=="Yubico",\
          RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';

      # Replace gnome-keyring with an alternative Secret Service provider when
      # passwordless U2F is active, since gnome-keyring cannot auto-unlock
      # without the login password.
      gnome.gnome-keyring = lib.mkIf
        (config.curios.security.keyringProvider != "gnome-keyring") {
          enable = lib.mkForce false;
        };
    };

    environment.systemPackages =
      [
        pkgs.opensc # Set of librairies for smart cards
        pkgs.yubikey-manager # ykman
      ] ++ lib.optionals
      (config.curios.security.keyringProvider == "keepassxc"
        && !config.curios.desktop.utility.keepassxc.enable)
      [ pkgs.keepassxc ];

    # When using an alternative keyring provider, override the COSMIC portal
    # configuration so sandboxed apps (Flatpak) use the correct Secret backend.
    # We must include the default fallback or other portals (file chooser, etc.)
    # will break. The package-provided cosmic-portals.conf is replaced entirely
    # when xdg.portal.config is set for the "cosmic" desktop.
    #xdg.portal.config = lib.mkIf
    #  (config.curios.security.keyringProvider != "gnome-keyring") {
    #    cosmic = {
    #      default = [ "cosmic" "gtk" ];
    #    } // lib.optionalAttrs
    #      (config.curios.security.keyringProvider == "oo7") {
    #      "org.freedesktop.impl.portal.Secret" = [ "oo7" ];
    #    };
    #  };
  };
}
