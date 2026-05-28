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
