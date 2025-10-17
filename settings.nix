# Custom settings goes here.
# Could be edited - This file will NOT be modified by update script later.
# Must be imported by configuration.nix
# Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# See: https://nixos.org/manual/nixos/stable/
# man configuration.nix
#
# Use `sudo nixos-rebuild switch` command in a terminal after an update in this file.

{ config, lib, pkgs, ... }:
let
  # App autostart example: It copy the desktop file from the package $package/share/applications/$srcPrefix$name.desktop
  # to $out/etc/xdg/autostart/$name.desktop so the app will be launched on user graphical session opening.
  # See: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/make-startupitem/default.nix
  # Next step: add 'protonvpn-gui-autostart' to "environment.systemPackages" below.
  protonvpn-gui-autostart = pkgs.makeAutostartItem {
    name = "protonvpn-app";
    package = pkgs.protonvpn-gui;
    appendExtraArgs = [ "--start-minimized" ]; # append extra arguments to protonvpn-app Exec
  };
  # Autostart Steam client in big picture mode example.
  # add 'steam-bigpicture-autostart' to "environment.systemPackages" below.
  # desktop.apps.gaming.enable option set to true is required. See below.
  steam-bigpicture-autostart = pkgs.makeAutostartItem {
    name = "steam";
    package = pkgs.steam;
    appendExtraArgs = [ "-bigpicture" ];
  };
in
{
  ### CuriOS options settings goes here:
  curios = {
    system = {
      hostname = "CuriOS";
      i18n.locale = "en_US.UTF-8";
      keyboard = "us";
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
    # Required modules:
    bootefi.enable = lib.mkDefault true;
    bootefi.kernel.latest = lib.mkDefault true; # Use latest stable kernel available if true, otherwise use LTS kernel.
    desktop.cosmic.enable = lib.mkDefault true;
    fonts.enable = lib.mkDefault true; # Fira, Noto, some Nerds fonts, JetBrains Mono
    networking.enable = lib.mkDefault true; # NetworkManager (required by COSMIC).
    shell.zsh.enable = lib.mkDefault true; # ZSH shell, REQUIRED
    # File system - updated by curios-install during ISO install
    filesystems.luks.enable = lib.mkDefault true;
    filesystems.minimal.enable = lib.mkDefault false;
    ### Modules below SHOULD be activated on user needs:
    desktop.apps = {
      basics.enable = lib.mkDefault true; # Brave browser, Alacritty, Bitwarden, Signal, Yubico auth, Gimp3, EasyEffects, ProtonVPN gui.
      appImage.enable = lib.mkDefault false; # Enabling Linux AppImage
      crypto = {
        enable = false; # Cryptocurrencies desktop apps. Required by desktop.apps.crypto options below.
        btc.enable = false; # Bitcoin - Electrum, Sparrow wallets - Bisq2 decentralized exchange.
      };
      devops = {
        enable = false; # Required by desktop.apps.devops options below. + Cloudlfared
        networks.enable = false; # Nmap, Zenmap, Wireshark
        go.enable = false; # Go, gofmt, JetBrains GoLand
        python312.enable = false; # Python3.12, pip, setuptools, JetBrains PyCharm-Community
        rust.enable = false; # Rustc, cargo, rust-analyzer, clippy + more, JetBrains RustRover
      };
      gaming.enable = false; # Steam, Heroic Launcher, gamemoderun, Input-Remapper, TeamSpeak6 client
      studio.enable = false; # OBS, Audacity, DaVinci Resolve
      office.enable = false; # LibreOffice suite
    };
    services = {
      enable = true; # Flatpak + flathub/cosmic repos, pipewire
      printing.enable = false; # CUPS
      sshd.enable = false; # SSH daemon
      ai.enable = false; # Ollama with mistral-nemo, open-webui
    };
    virtualisation = {
      enable = false; # docker, docker buildx, docker-compose, QEMU/KVM, libvirt, virt-manager
      wine.enable = false; # Wine 32 and 64 bits with Wayland support.
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
      getty.enable = false; # WARNING: will prevent TTY console login
      networkManager.enable = false; # TODO: proton-vpn bug if set to true
      networkManager-dispatcher.enable = false; # TODO: proton-vpn bug if set to true
      nix-daemon.enable = false;
      nscd.enable = false;
      rescue.enable = false;
      rtkit-daemon.enable = false;
      sshd.enable = false;
      user.enable = false; # TODO: 'Flatpak run' bug if set to true
      wpa_supplicant.enable = false;
    };
  };

  ### NixOS packages
  environment.systemPackages = [
    #protonvpn-gui-autostart # Uncomment this line to autostart protonvpn-gui on user graphical session.
    #steam-bigpicture-autostart # Uncomment this line to autostart Steam client in big picture mode.
    # Add your packages pkgs.foobar here:
  ];

  ### Change user settings here:
  users.users.nixos = {
    description = "Me";
    #openssh.authorizedKeys.keys = [ "ssh-ed25519 XXXXXXX me@me.com" ];  # Set your SSH pubkey here
  };

  ### Change general settings here:
  # networking
  networking = {
    nameservers = [ "9.9.9.9" "1.1.1.1" "2620:fe::fe" "2620:fe::9" ]; # Quad9 and cloudflare DNS servers.
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
      "default.clock.quantum" = 512; # Keep increasing the quant value until you get no sound crackles
      "default.clock.min-quantum" = 256;
      "default.clock.max-quantum" = 16384;
    };
  };
  # Ollama
  services.ollama = {
    # For AMD Ryzen 7 PRO hardware, uncomment lines below.
    # To adjust value, see command result of: nix-shell -p "rocmPackages.rocminfo" --run "rocminfo" | grep "gfx"
    #environmentVariables = {
    #  HCC_AMDGPU_TARGET = "gfx1103"; # used to be necessary, but doesn't seem to anymore
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
  system.stateVersion = "25.05"; # Did you read the comment?
}