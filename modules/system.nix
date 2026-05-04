# system options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.system = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED - Enable CuriOS system options.";
      };
      ansible.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Ansible automation tool.";
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "CuriOS";
        description = "Set system networking hostname.";
      };
      i18n.locale = lib.mkOption {
        type = lib.types.str;
        default = "en_US.UTF-8";
        description = "Set system i18n locale settings.";
      };
      keyboard = lib.mkOption {
        type = with lib.types; either str path;
        default = "us";
        description = "Set system keyboard map settings.";
      };
      pkgs = {
        autoupgrade.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automated packages update and cleanup.";
        };
        gc.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automated packages garbage collect.";
        };
      };
      timeZone = lib.mkOption {
        type = lib.types.str;
        default = "Etc/GMT";
        description = ''
          Set system time zone. See <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>
                      for a comprehensive list of possible values for this setting.'';
      };
      languages = {
        go.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Go language and gofmt.";
        };
        java.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Java language - JetBrains OpenJDK.";
        };
        javascript.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "NodeJS (npm, npx) Javascript runtime and eslint.";
        };
        javascript.bun.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "A fast JavaScript toolkit.";
        };
        python312.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description =
            "Enable Python 3.12, pip, setuptools, cryptography, uv, pyright and ruff.";
        };
        python313.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description =
            "Enable Python 3.13, pip, setuptools, cryptography, uv, pyright and ruff.";
        };
        ruby.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Ruby language and gems.";
        };
        rust.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description =
            "Enable Rust language with rustup, cargo and build tools.";
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.system.enable {
    networking.hostName = lib.mkForce config.curios.system.hostname;
    time.timeZone = lib.mkDefault config.curios.system.timeZone;
    i18n.defaultLocale = lib.mkDefault config.curios.system.i18n.locale;

    # Keyboard settings
    console.keyMap = lib.mkDefault config.curios.system.keyboard;

    system.autoUpgrade = {
      enable = lib.mkDefault config.curios.system.pkgs.autoupgrade.enable;
      dates = "03:40";
      randomizedDelaySec = "3min";
      # Reboot on new kernel, initrd or kernel module.
      allowReboot = false;
    };

    # Automatic collect garbage
    nix.gc = {
      automatic = lib.mkDefault config.curios.system.pkgs.gc.enable;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    environment.systemPackages =
      lib.optionals config.curios.system.ansible.enable [ pkgs.ansible ]
      ++ lib.optionals config.curios.system.languages.go.enable [
        pkgs.go
        pkgs.golangci-lint
      ] ++ lib.optionals config.curios.system.languages.java.enable
      [ pkgs.jetbrains.jdk ]
      ++ lib.optionals config.curios.system.languages.javascript.enable [
        pkgs.eslint
        pkgs.nodejs_24
      ] ++ lib.optionals config.curios.system.languages.javascript.bun.enable
      [ pkgs.bun ]
      ++ lib.optionals config.curios.system.languages.python312.enable [
        pkgs.python312
        pkgs.python312Packages.pip
        pkgs.python312Packages.setuptools
        pkgs.python312Packages.cryptography
        pkgs.python312Packages.uv
        pkgs.pyright
        pkgs.ruff
      ] ++ lib.optionals config.curios.system.languages.python313.enable [
        pkgs.python313
        pkgs.python313Packages.pip
        pkgs.python313Packages.setuptools
        pkgs.python313Packages.cryptography
        pkgs.python313Packages.uv
        pkgs.pyright
        pkgs.ruff
      ]
      ++ lib.optionals config.curios.system.languages.ruby.enable [ pkgs.ruby ]
      ++ lib.optionals config.curios.system.languages.rust.enable [
        pkgs.rustup
        pkgs.cargo-c
        pkgs.clang
        pkgs.libxkbcommon
        pkgs.llvmPackages.bintools
        pkgs.pkg-config
      ];
  };
}
