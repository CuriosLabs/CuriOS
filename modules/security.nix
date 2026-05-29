# Security options (U2F/FIDO2, YubiKey, hardening, etc.)

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.security = {
      u2f = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable U2F/FIDO2 authentication with pam_u2f (YubiKey, Nitrokey, etc.).
            Password authentication remains available as fallback (sufficient control).
            Works with cosmic-greeter, greetd, login, and sudo.

            Origin and appid default to "curios" so that the same YubiKey enrollment
            can be reused across multiple machines without extra configuration.
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
            Requires curios.security.u2f.enable to take effect.
          '';
        };
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
            This uses systemd-cryptenroll + crypttabExtraOpts (modern path with boot.initrd.systemd).
            Requires a YubiKey that supports FIDO2 and the hmac-secret extension (most YubiKey 5+).
            A strong recovery passphrase must always be kept — it is the only way to boot if the
            YubiKey is lost, damaged, or not present.
            This option is independent from curios.security.u2f.enable (login vs disk encryption).
          '';
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.security.u2f.enable {
    security.pam.u2f = {
      # U2F are sufficient replacements to passwords.
      control = "sufficient";
      enable = true;
      settings = {
        cue = true;
        interactive = true;
        nouserok = true; # Do not fail if the user has no U2F key configured
        origin = config.curios.security.u2f.origin;
        appid = config.curios.security.u2f.appid;
      };
    };

    security.pam.services = {
      cosmic-greeter.u2fAuth = true;
      greetd.u2fAuth = true;
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };

    # Lock screen when YubiKey is removed (physical security feature)
    services.udev.extraRules = lib.mkIf config.curios.security.u2f.lockOnRemove ''
      ACTION=="remove",\
        SUBSYSTEM=="usb",\
        ENV{ID_VENDOR_ID}=="1050",\
        ENV{ID_VENDOR}=="Yubico",\
        RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };
}
