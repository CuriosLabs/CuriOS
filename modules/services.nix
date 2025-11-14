# CuriOS services base configuration

{ config, lib, pkgs, ... }:
{
  # Declare options
  options = {
    curios.services = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CuriOS services.";
      };
      printing.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable CUPS printing services.";
      };
      sshd.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable SSH daemon services.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.services.enable {
    # Services:
    services = {
      # Firmware update - See: https://wiki.nixos.org/wiki/Fwupd
      fwupd.enable = true;
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
        displayManager.sessionCommands = "setxkbmap -layout ${config.curios.system.keyboard}";
      };
      # OpenSSH server.
      openssh = {
        enable = lib.mkDefault config.curios.services.sshd.enable;
        settings = {
          PermitRootLogin = "no";
          StrictModes = true;
          PasswordAuthentication = false; # Set users.users.<name>.openssh.authorizedKeys.keys to your ssh pubkey
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
          "context.properties" = {
            "default.clock.rate" = 48000;
          };
        };
        extraConfig.pipewire-pulse."92-low-latency" = {
          "context.properties" = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = { };
            }
          ];
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
    };

    # systemd config
    systemd = {
      # Systemd settings for NixOS channel 25.05
      extraConfig = "DefaultTimeoutStopSec=10s"; # Reduce timeout waiting to 10sec
      # Systemd settings for NixOS channel 25.11
      #settings.Manager = {
      #  DefaultTimeoutStopSec = "10s";
      #};
      # Flatpak system, add repo
      services.flatpak-repo = {
        enable = true;
        description = "Flatpak add default repos";
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.flatpak ];
        script =
          if config.curios.desktop.cosmic.enable then
            ''
              /run/current-system/sw/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
              /run/current-system/sw/bin/flatpak remote-add --if-not-exists cosmic https://apt.pop-os.org/cosmic/cosmic.flatpakrepo
            ''
          else
            ''
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
            ExecStart = "/run/current-system/sw/bin/flatpak update --noninteractive --assumeyes";
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
    programs.ssh.startAgent = true; # SSH start-agent - not compatible with gnupg.agent SSH - Cosmic already set services.gnome.gnome-keyring.enable to true - cannot run both.
    services.gnome.gnome-keyring.enable = lib.mkForce false;
    security.rtkit.enable = true; # realtime scheduling priority for pipewire.
  };
}
