# Security options (U2F/FIDO2, YubiKey, etc.)

{ config, lib, pkgs, ... }:
let
  oo7Pam = pkgs.callPackage ../pkgs/oo7-pam { };

  # PAM rules for the oo7 keyring module.  These orders are chosen to sit
  # safely inside the standard NixOS PAM stacks without colliding with the
  # automatically-assigned orders from utils.pam.autoOrderRules.
  oo7PamRules = lib.optionalAttrs (config.curios.security.keyringProvider == "oo7") {
    rules = {
      # Early unix: prompt for password and set PAM_AUTHTOK before oo7 runs.
      # This mirrors NixOS's built-in early-auth block used by gnome-keyring.
      auth.unix-early = {
        order = 11400;
        control = "optional";
        modulePath = "${pkgs.linux-pam}/lib/security/pam_unix.so";
        settings = {
          nullok = true;
          likeauth = true;
        };
      };
      # Auth: placed just after unix-early so PAM_AUTHTOK is already populated.
      auth.oo7 = {
        order = 11550;
        control = "optional";
        modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
      };
      # Session: placed after systemd (10200) so the user session is ready.
      session.oo7 = {
        order = 10250;
        control = "optional";
        modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
        settings = { auto_start = true; };
      };
      # Password: placed after unix (10200) so the new password is available.
      password.oo7 = {
        order = 10250;
        control = "optional";
        modulePath = "${oo7Pam}/lib/security/pam_oo7.so";
      };
    };
  };
in
{
  # Declare options
  options = {
    curios.security = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED CuriOS security options.";
      };
      u2f = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable U2F/FIDO2 authentication with pam_u2f (YubiKey, Nitrokey, etc.).
            Password authentication remains available as fallback (sufficient control).
            Works with cosmic-greeter, greetd, login, and sudo.
            Set it with curios-manager -> Security -> Register primary Yubikey.
          '';
        };

        appid = lib.mkOption {
          type = lib.types.str;
          default = "curios";
          example = "curios";
          description = ''
            AppID used by pam_u2f.
            Defaults to the same value as `origin` for simplicity.
            Must match what is passed to `pamu2fcfg -i` during enrollment.
          '';
        };

        lockOnRemove = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Automatically lock all user sessions when a YubiKey is physically removed.
          '';
        };

        origin = lib.mkOption {
          type = lib.types.str;
          default = "curios";
          example = "curios";
          description = ''
            Origin used by pam_u2f.

            Default is "curios" (instead of pam-u2f's built-in default of `pam://$HOSTNAME`).
            Using a stable value makes it trivial to use the same YubiKey enrollment
            across multiple machines.

            Change this only if you have a good reason (e.g. your own domain name).
            The value must match what is passed to `pamu2fcfg -o`.
          '';
        };
      };

      keyringProvider = lib.mkOption {
        type = lib.types.enum [ "gnome-keyring" "keepassxc" "oo7" ];
        default = "oo7";
        description = ''
          Select the Secret Service (freedesktop.org) provider used while U2F is active.

          Use "keepassxc" when using passwordless authentication because
          gnome-keyring requires the login password to auto-unlock, which defeats
          the purpose of passwordless U2F login. KeePassXC can act as a Secret
          Service provider and is unlocked independently via its own database
          password or hardware key.

          When "keepassxc" is selected, the gnome-keyring daemon is disabled
          but the package remains installed as a COSMIC dependency.

          You must manually enable Secret Service integration in KeePassXC:
          Tools → Settings → Secret Service Integration.

          Use "oo7" for the oo7 Secret Service provider. Note that oo7 creates
          an encrypted keyring which requires a password or systemd credential
          (`oo7.keyring-encryption-password`) to unlock. It does not auto-unlock
          with U2F passwordless login without additional credential setup.
        '';
      };

      # LUKS disk encryption with FIDO2 (YubiKey etc.) is configured here
      # but applied in modules/filesystems/filesystems-luks-v2.nix so that
      # the core LUKS module stays focused on filesystem layout.
      luksFido2 = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable FIDO2 token support (YubiKey, etc.) for unlocking the LUKS root volume during boot.
            Requires a YubiKey that supports FIDO2 and the hmac-secret extension (most YubiKey 5+).
            A strong recovery passphrase must always be kept — it is the only way to boot if the
            YubiKey is lost, damaged, or not present.
            Set it with curios-manager -> Security -> Enroll Yubikey for disk decryption.
          '';
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.security.enable {
    security.pam.u2f = {
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

    security.pam.services = {
      login = {
        u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
      } // oo7PamRules;
      greetd = {
        u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
      } // oo7PamRules;
      cosmic-greeter = {
        u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
      } // oo7PamRules;
      sudo.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
    };

    # Lock screen when YubiKey is removed (physical security feature)
    services.udev.extraRules = lib.mkIf config.curios.security.u2f.lockOnRemove ''
      ACTION=="remove",\
        SUBSYSTEM=="usb",\
        ENV{ID_VENDOR_ID}=="1050",\
        ENV{ID_VENDOR}=="Yubico",\
        RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';

    # Replace gnome-keyring with an alternative Secret Service provider when
    # passwordless U2F is active, since gnome-keyring cannot auto-unlock
    # without the login password.
    services.gnome.gnome-keyring = lib.mkIf
      (config.curios.security.keyringProvider != "gnome-keyring") {
        enable = lib.mkForce false;
      };

    environment.systemPackages = lib.optionals
      (config.curios.security.keyringProvider == "keepassxc"
        && !config.curios.desktop.utility.keepassxc.enable)
      [ pkgs.keepassxc ]
      ++ lib.optionals
      (config.curios.security.keyringProvider == "oo7")
      [
        pkgs.oo7
        pkgs.oo7-portal
        pkgs.gcr
        # Ensure oo7's D-Bus service file wins over gnome-keyring's so
        # org.freedesktop.secrets activation starts oo7-daemon.
        (lib.hiPrio pkgs.oo7-server)
      ];

    # When using an alternative keyring provider, override the COSMIC portal
    # configuration so sandboxed apps (Flatpak) use the correct Secret backend.
    # We must include the default fallback or other portals (file chooser, etc.)
    # will break. The package-provided cosmic-portals.conf is replaced entirely
    # when xdg.portal.config is set for the "cosmic" desktop.
    xdg.portal.config = lib.mkIf
      (config.curios.security.keyringProvider != "gnome-keyring") {
        cosmic = {
          default = [ "cosmic" "gtk" ];
        } // lib.optionalAttrs
          (config.curios.security.keyringProvider == "oo7") {
          "org.freedesktop.impl.portal.Secret" = [ "oo7" ];
        };
      };
  };
}
