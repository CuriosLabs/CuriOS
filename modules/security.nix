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
          description =
            "Enable U2F/FIDO2 authentication with pam_u2f (YubiKey, Nitrokey, etc.).";
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
          description =
            "Automatically lock all user sessions when a YubiKey is physically removed.";
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
        description =
          "EXPERIMENTAL - Select the Secret Service (freedesktop.org) provider used while U2F is active.";
      };

      # LUKS disk encryption with FIDO2 (YubiKey etc.) is configured here
      # but applied in modules/filesystems/filesystems-luks-v2.nix so that
      # the core LUKS module stays focused on filesystem layout.
      luksFido2 = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description =
            "Enable FIDO2 key support (YubiKey, etc.) for unlocking the LUKS disk volume during boot.";
        };
      };

      tpm2 = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable TPM2 support.";
        };
        integrityCheck = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Run post-boot TPM2 integrity check.";
        };
        measuredBoot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "TPM2 measure boot phases in initrd and systemd.";
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
          cosmic-greeter.u2f.enable =
            lib.mkDefault config.curios.security.u2f.enable;
          greetd.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
          login.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
          sudo.u2f.enable = lib.mkDefault config.curios.security.u2f.enable;
        };
      };

      # TPM2
      tpm2 = {
        abrmd.enable = false;
        enable = config.curios.security.tpm2.enable;
        pkcs11.enable = config.curios.security.tpm2.enable;
        tctiEnvironment.enable = config.curios.security.tpm2.enable;
      };

      rtkit.enable =
        lib.mkDefault true; # realtime scheduling priority for pipewire.

      # Show password feedback for sudo command.
      sudo.extraConfig = "Defaults pwfeedback";
    };

    systemd = {
      tpm2 = {
        enable = config.curios.security.tpm2.enable;
        pcrphases.enable = config.curios.security.tpm2.measuredBoot;
      };

      services = {
        # TPM2 PCR integrity check: compare stable PCRs (0,4,7) against baseline
        # and alert the user if they changed (e.g. Secure Boot disabled, bootloader modified)
        # The check itself is implemented in `curios-update --pcr-check`.
        curios-pcr-check = lib.mkIf (config.curios.security.tpm2.enable
          && config.curios.security.tpm2.integrityCheck) {
            description = "CuriOS TPM PCR integrity check";
            after = [ "multi-user.target" "systemd-pcrphase.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "/run/current-system/sw/bin/curios-update --pcr-check";
            };
          };
      };
    };

    boot = {
      # Disable kexec service (prevents systemd kexec from starting)
      kexec.enable = lib.mkForce false;

      # Hard block at kernel level via sysctl (kernel param kexec_load_disabled=1
      # does not persist on kernel 7.3, but sysctl forced via systemd-sysctl works)
      kernel.sysctl = {
        "kernel.kexec_load_disabled" = lib.mkForce "1";
        # For CVE-2026-98432 ONLY if you plan to run servers written in Go
        # or with MPTCP capability.
        #"net.mptcp.enabled" = lib.mkForce "0";
      };

      # TPM2
      initrd.systemd.tpm2 = {
        enable = config.curios.security.tpm2.enable;
        pcrphases.enable = config.curios.security.tpm2.measuredBoot;
        #pcrosseparator.enable = config.curios.security.tpm2.measuredBoot;
      };

      # Remove UKI condition from initrd pcrphase service when using Limine
      initrd.systemd.services = lib.mkIf config.curios.bootefi.limine.enable {
        systemd-pcrphase-initrd.unitConfig.ConditionSecurity = lib.mkForce "";
      };
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

      gnome = {
        # Replace gnome-keyring with an alternative Secret Service provider when
        # passwordless U2F is active, since gnome-keyring cannot auto-unlock
        # without the login password.
        gnome-keyring =
          lib.mkIf (config.curios.security.keyringProvider != "gnome-keyring") {
            enable = lib.mkForce false;
          };
        # Disable Gnome keyring for SSH agent
        gcr-ssh-agent.enable = lib.mkDefault false;
      };
    };

    environment.systemPackages = [
      pkgs.opensc # Set of librairies for smart cards
      pkgs.tpm2-tools
      #pkgs.yubico-piv-tool # For using a YubiKey as a PIV smart card.
      pkgs.yubikey-manager # ykman
      # BPF LSM tools for kernel security monitoring and policy enforcement
      pkgs.bpftools # bpftool - inspect and load BPF programs
      pkgs.bpftrace # bpftrace - dynamic tracing (can be used with BPF LSM)
    ] ++ lib.optionals (config.curios.security.keyringProvider == "keepassxc"
      && !config.curios.desktop.utility.keepassxc.enable) [ pkgs.keepassxc ];

    # NOTE: opensc-pkcs11 library command to test a Yubikey with PKSC#11 (PIV method):
    # nix-shell -p opensc --run "ssh-keygen -D $(nix-build '<nixpkgs>' -A opensc --no-out-link)/lib/opensc-pkcs11.so"

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
