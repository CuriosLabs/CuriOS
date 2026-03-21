# CuriOS services base configuration

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.services = {
      ai.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED CuriOS services - Flatpak, pipewire, fwupd...";
      };
      ollama.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Ollama(local AI) and open-webui services.";
      };
      printing.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable CUPS printing services.";
      };
      sshd.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable SSH daemon service.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.services.enable {
    # AI webapp desktop shortcuts
    environment.systemPackages = lib.optionals config.curios.services.ollama.enable [
      # AI webapp desktop shortcuts
      (import ./desktop-apps/webapp-ollama.nix)
    ];

    # Services:
    services = {
      # Firmware update - See: https://wiki.nixos.org/wiki/Fwupd
      # Required by curios-manager
      fwupd.enable = true;

      # Ollama, see: https://wiki.nixos.org/wiki/Ollama
      ollama = {
        enable = lib.mkDefault config.curios.services.ollama.enable;
        #home = "/home/ollama";
        # Optional: preload models, see https://ollama.com/library
        # or use `ollama pull <model-name>` (may be faster)
        #loadModels = [ "mistral-nemo:latest" ]; # get download status with: 'systemctl status ollama-model-loader.service'
        # GPU accel
        # "false": 100% CPU, "cuda": modern Nvidia GPU, "rocm": modern AMD GPU
        acceleration = if config.curios.hardware.nvidiaGpu.enable then
          "cuda"
        else if config.curios.hardware.amdGpu.enable then
          "rocm"
        else if config.curios.hardware.intelGpu.enable then
          "vulkan"
        else
          false;
        # Ollama server port
        port = 11434;
      };
      # Open WebUI, see: https://docs.openwebui.com/
      open-webui = {
        enable = lib.mkDefault config.curios.services.ollama.enable;
        environment = {
          # See https://docs.openwebui.com/getting-started/env-configuration/
          HOME = "/var/lib/open-webui";
          OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
          # Disable authentication
          WEBUI_AUTH = "False";
        };
        port = 8080;
      };

      # X server
      xserver = {
        enable = lib.mkDefault true;
        # keyboard settings, see: 'localectl status' , 'setxkbmap -query' ?
        xkb = {
          layout = config.curios.system.keyboard;
          model = "pc105";
          variant = "";
          #options = "eurosign:e,caps:escape";
        };
        displayManager.sessionCommands =
          "setxkbmap -layout ${config.curios.system.keyboard}";
      };
      # OpenSSH server.
      openssh = {
        enable = lib.mkDefault config.curios.services.sshd.enable;
        settings = {
          PermitRootLogin = "no";
          StrictModes = true;
          # Set users.users.<name>.openssh.authorizedKeys.keys to your ssh pubkey
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PrintMotd = true;
          UsePAM = true;
          X11Forwarding = false;
        };
      };
      # Enable CUPS to print documents.
      printing.enable = lib.mkDefault config.curios.services.printing.enable;
      # Enabling Flatpak
      flatpak.enable = true;
      # Enable sound.
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        extraConfig.pipewire."92-low-latency" = {
          "context.properties" = { "default.clock.rate" = 48000; };
        };
        extraConfig.pipewire-pulse."92-low-latency" = {
          "context.properties" = [{
            name = "libpipewire-module-protocol-pulse";
            args = { };
          }];
          "pulse.properties" = {
            "pulse.min.req" = "256/48000";
            "pulse.default.req" = "512/48000";
            "pulse.max.req" = "512/48000";
            "pulse.min.quantum" = "256/48000";
            "pulse.max.quantum" = "16384/48000";
          };
          "stream.properties" = {
            "node.latency" = "512/48000";
            "resample.quality" = 1;
          };
        };
      };
      # TODO: Custom udev rules for USB drive - trigger mounting upon insertion
      # See: `udisksctl mount -b /dev/sda1` `ls -lh /run/media/${USER}`
      #udev.extraRules = ''
      #  # USB drive mount to /run/media/$USER
      #  ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", RUN{program}+="/run/current-system/sw/bin/udisksctl mount -b $devnode"
      #'';
      #udev.extraRules = ''
      #  # USB drive mount to /media
      #  ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --automount=yes --collect $devnode /media"
      #'';
      # OR
      #services.udev.packages = [
      #  (pkgs.writeTextFile {
      #    name = "udisks2-rules-share-mounts";
      #    text = ''
      #      ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"
      #    '';
      #    destination = "/etc/udev/rules.d/99-udisks2.rules";
      #  })
      #];
      #systemd.tmpfiles.rules = [
      #  "d /media 0755 root root 99999y"
      #];
    };

    # systemd config
    systemd = {
      # Systemd settings for NixOS channel 25.11
      settings.Manager = { DefaultTimeoutStopSec = "10s"; };
      # Flatpak system, add repo
      services.flatpak-repo = {
        enable = true;
        description = "Flatpak add default repos";
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.flatpak ];
        script = if config.curios.cosmic.enable then ''
          /run/current-system/sw/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
          /run/current-system/sw/bin/flatpak remote-add --if-not-exists cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo
        '' else ''
          /run/current-system/sw/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        '';
      };
      # Flatpak user auto update
      # systemctl --user list-units --type=service
      # systemctl --user list-timers
      # systemctl --user status flatpak-update.timer
      user = {
        services.flatpak-update = {
          enable = true;
          description = "Flatpak user update";
          #path = [ pkgs.flatpak ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              "/run/current-system/sw/bin/flatpak update --noninteractive --assumeyes";
          };
          wantedBy = [ ];
        };
        timers.flatpak-update = {
          enable = true;
          description = "Flatpak user update";
          timerConfig = {
            OnStartupSec = "30s";
            OnUnitInactiveSec = "24h";
            OnUnitActiveSec = "24h";
            RandomizedDelaySec = "2m";
          };
          wantedBy = [ "timers.target" ];
        };
      };
    };

    # Other
    # SSH start-agent - not compatible with gnupg.agent SSH - Cosmic already set services.gnome.gnome-keyring.enable to true - cannot run both.
    #programs.ssh.startAgent = true;
    #services.gnome.gnome-keyring.enable = lib.mkForce false;
    security.rtkit.enable = true; # realtime scheduling priority for pipewire.
  };
}
