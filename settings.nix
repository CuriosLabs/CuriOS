# Custom settings goes here.
# Could be edited - This file will NOT be modified by update script later.
# Must be imported by configuration.nix
# Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# See: https://nixos.org/manual/nixos/stable/
# See: https://github.com/CuriosLabs/CuriOS
# man configuration.nix
#
# Use `sudo nixos-rebuild switch` command in a terminal after an update in this file.

{ config, lib, pkgs, ... }:
let
  # Following variables can be edited.
  # Default user password. Change it later, after your first boot with COSMIC Parameters > System & Accounts
  # OR with the 'passwd' command line.
  # Do **NOT** set your real password HERE !
  password = "changeme";
in {
  ### CuriOS options settings goes here:
  curios = {
    system = {
      hostname = "CuriOS";
      i18n.locale = "en_US.UTF-8";
      keyboard = "us";
      pkgs = {
        # Enable automated packages update and cleanup
        autoupgrade.enable = true;
        # Enable automated packages update and cleanup
        gc.enable = true;
      };
      timeZone = "Etc/GMT";
    };
    ### Activate or deactivate CuriOS modules/ from here:
    # Hardware platform settings updated by curios-install during ISO install
    platform.amd64.enable = lib.mkDefault true;
    platform.rpi4.enable = lib.mkDefault false;
    # Hardware related modules - updated by curios-install during ISO install
    hardware = {
      # Modern AMD GPU
      amdGpu.enable = lib.mkDefault false;
      # Modern Nvidia GPU
      nvidiaGpu.enable = lib.mkDefault false;
      # EXPERIMENTAL - laptop battery saver
      laptop.enable = false;
    };
    # REQUIRED modules:
    # Enable Restic backup
    backup.enable = lib.mkDefault true;
    bootefi.enable = lib.mkDefault true;
    # Use latest stable kernel available if true, otherwise use LTS kernel.
    bootefi.kernel.latest = lib.mkDefault true;
    desktop.cosmic.enable = lib.mkDefault true;
    # Fira, Noto, some Nerds fonts, JetBrains Mono
    fonts.enable = lib.mkDefault true;
    # NetworkManager (required by COSMIC).
    networking.enable = lib.mkDefault true;
    # ZSH shell, REQUIRED
    shell.zsh.enable = lib.mkDefault true;
    # File system - updated by curios-install during ISO install
    filesystems.luks.enable = lib.mkDefault true;
    filesystems.minimal.enable = lib.mkDefault false;
    ### Modules below SHOULD be activated on user needs:
    desktop.apps = {
      # Brave browser, Alacritty, Signal, Yubico auth, Gimp3, EasyEffects.
      basics.enable = lib.mkDefault true;
      # Enabling Linux AppImage
      appImage.enable = lib.mkDefault true;
      # Various web browser
      browser = {
        chromium.enable = false;
        firefox.enable = false;
        librewolf.enable = false;
        vivaldi.enable = false;
      };
      crypto = {
        # Cryptocurrencies desktop apps.
        # Required by desktop.apps.crypto options below.
        enable = false;
        # btc.enable REQUIRE appImage.enable = true !!!
        # Bitcoin - Electrum wallet - Bisq2 decentralized exchange.
        btc.enable = false;
      };
      devops = {
        # Desktop apps for developers - Neovim+LazyVim, git for github (gh),
        # shellcheck, statix
        enable = true;
        # Cloudflare tunnel client
        cloudflared.enable = false;
        editor = {
          # Set Neovim as the default editor instead of nano.
          default.nvim.enable = false;
          # Zed.dev code editor
          zed.enable = true;
          # MS code editor
          vscode.enable = false;
        };
        # Go, gofmt, JetBrains GoLand
        go.enable = false;
        # NodeJS (npm)
        javascript.enable = false;
        # Python3.12, pip, setuptools, JetBrains PyCharm-Community
        python312.enable = false;
        python313.enable = false;
        # Rustc, cargo, rust-analyzer, clippy + more, JetBrains RustRover
        rust.enable = false;
        # Nmap, Zenmap, Wireshark, Remmina
        networks.enable = false;
      };
      gaming = {
        # Steam, Heroic Launcher, gamemoderun, Input-Remapper, TeamSpeak6 client
        enable = false;
        steam.bigpicture.autoStart = false;
      };
      # OBS, Audacity, DaVinci Resolve
      studio.enable = false;
      office = {
        # Default office desktop apps - Obsidian (notes/ideas).
        enable = true;
        # LibreOffice suite
        libreoffice.enable = false;
        # ONLYOFFICE suite
        onlyoffice.desktopeditors.enable = true;
        # Mozilla Thunderbird email client
        thunderbird.enable = false;
        # Projects management apps - replace baseUrl with your company Jira URL.
        projects = {
          jira = {
            enable = false;
            baseUrl = "example.atlassian.net";
          };
        };
        # conferencing web apps
        conferencing = {
          slack.enable = false;
          teams.enable = false;
          zoom.enable = false;
        };
      };
      vpn = {
        # ProtonVPN with GUI
        proton.enable = false;
        proton.autoStart = false;
        # tailscale.com VPN
        tailscale.enable = false;
        # mullvad VPN GUI
        mullvad.enable = false;
      };
      ai = {
        # ChatGPT web app
        chatgpt.enable = true;
        # Claude web app
        claude.enable = true;
        # Google Gemini CLI
        gemini.enable = false;
        # Grok web app
        grok.enable = true;
        # lmstudio.ai local AI model
        lmstudio.enable = false;
        # Mistral LeChat web app
        mistral.enable = true;
      };
      chat = {
        # Signal.org desktop app
        signal.enable = true;
        # WhatsApp web app
        whatsapp.enable = true;
      };
      utility = {
        # Bitwarden password manager
        bitwarden.enable = true;
        # Flameshot screenshot app
        flameshot.enable = false;
        # KeePassXC password manager
        keepassxc.enable = false;
      };
    };
    services = {
      # REQUIRED - Flatpak + flathub/cosmic repos, pipewire
      enable = true;
      # CUPS printing
      printing.enable = false;
      # SSH daemon
      sshd.enable = false;
      # Ollama local AI with open-webui
      ai.enable = false;
    };
    virtualisation = {
      # QEMU/KVM, libvirt, virt-manager
      enable = false;
      # Docker containers + docker-compose, docker-buildx, lazydocker
      docker.enable = false;
      # Podman containers, replacement for Docker.
      podman.enable = false;
      # Wine 32 and 64 bits with Wayland support.
      wine.enable = false;
    };
    hardened = {
      # Hardened configurations -WIP-
      # Activate and test one by one - may break some programs
      # Check results with: `systemd-analyze security`
      accountsDaemon.enable = false;
      acpid.enable = false;
      cups.enable = false;
      dbus.enable = false;
      display-manager.enable = false;
      docker.enable = false;
      # WARNING: will prevent TTY console login if true:
      getty.enable = false;
      # TODO: proton-vpn bug if set to true:
      networkManager.enable = false;
      # TODO: proton-vpn bug if set to true:
      networkManager-dispatcher.enable = false;
      nix-daemon.enable = false;
      nscd.enable = false;
      rescue.enable = false;
      rtkit-daemon.enable = false;
      sshd.enable = false;
      # TODO: 'Flatpak run' bug if set to true:
      user.enable = false;
      wpa_supplicant.enable = false;
    };
  };

  ### NixOS packages
  environment.systemPackages = [
    # Add your packages here - find package name at https://search.nixos.org/packages
    #pkgs.inkscape-with-extensions
  ];

  ### Change user settings here:
  users = {
    mutableUsers = true;
    # Create plugdev group to access some USB devices without root privileges
    extraGroups.plugdev = { };
    # Define a user account
    # <user> name and description will be updated by curios-install during ISO install
    users.nixos = {
      isNormalUser = true;
      initialPassword = password;
      description = "My Name";
      extraGroups = [ "wheel" "audio" "sound" "video" "plugdev" "dialout" ]
        ++ lib.optionals config.curios.desktop.apps.crypto.enable [ "tty" ]
        ++ lib.optionals config.curios.networking.enable [ "networkmanager" ]
        ++ lib.optionals config.curios.virtualisation.enable [
          "libvirtd"
          "qemu-libvirtd"
          "kvm"
          "input"
          "disk"
        ]
        ++ lib.optionals config.curios.virtualisation.docker.enable [ "docker" ]
        ++ lib.optionals config.curios.virtualisation.podman.enable
        [ "podman" ];
      useDefaultShell = true;
      # Set your SSH pubkey here:
      #openssh.authorizedKeys.keys = [ "ssh-ed25519 XXXXXXX me@me.com" ];
    };
  };

  ### Change general settings here:
  # networking
  networking = {
    nameservers = [
      "9.9.9.9"
      "1.1.1.1"
      "2620:fe::fe"
      "2620:fe::9"
    ]; # Quad9 and cloudflare DNS servers.
    # Use DHCP to get an IP address:
    useDHCP = lib.mkDefault true;
    # Open ports in the firewall.
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    #firewall.enable = false;

    # Configure network proxy if necessary
    #proxy = {
    #  default = "http://user:password@proxy:port/";
    #  noProxy = "127.0.0.1,localhost,internal.domain";
    #};
  };
  # pipewire sound settings:
  services.pipewire = {
    extraConfig.pipewire."92-low-latency" = {
      # Keep increasing the quantum value until you get no sound crackles
      "default.clock.quantum" = 512;
      "default.clock.min-quantum" = 256;
      "default.clock.max-quantum" = 16384;
    };
  };
  # Ollama
  services.ollama = {
    # For AMD Ryzen 7 PRO hardware, uncomment lines below.
    # To adjust value, see command result of: nix-shell -p "rocmPackages.rocminfo" --run "rocminfo" | grep "gfx"
    #environmentVariables = {
    # used to be necessary, but doesn't seem to anymore
    #  HCC_AMDGPU_TARGET = "gfx1103";
    #};
    #rocmOverrideGfx = "11.0.2";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  # NixOS original channel (at first install).
  system.stateVersion = "25.11"; # Did you read the comment?
}
