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
  curiosModules = builtins.fromJSON (builtins.readFile ./modules.json);
  curiosHardened = builtins.fromJSON (builtins.readFile ./hardened.json);
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
      # Modern Intel GPU
      intelGpu.enable = lib.mkDefault false;
      # Modern Nvidia GPU
      nvidiaGpu.enable = lib.mkDefault false;
      # EXPERIMENTAL - laptop battery saver
      laptop.enable = false;
    };
    # REQUIRED modules - Do NOT edit:
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
    ### Modules below SHOULD be activated on user needs - EDIT ./modules.json:
    #desktop.apps = curios-settings."desktop.apps";
    inherit (curiosModules) desktopApps others services virtualisation;
    ### Hardened configurations -WIP-
    hardened = curiosHardened;
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
      initialHashedPassword = "";
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
    # Quad9 and cloudflare DNS servers.
    nameservers = [ "9.9.9.9" "1.1.1.1" "2620:fe::fe" "2620:fe::9" ];
    # Use DHCP to get an IP address:
    useDHCP = lib.mkDefault true;
    # Open ports in the firewall.
    #firewall.allowedTCPPorts = [ ... ];
    #firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    firewall.enable = lib.mkDefault true;

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
    environmentVariables = {
      # Set Ollama service model context length
      # Adjust to the model VRAM usage, the bigger the better
      OLLAMA_CONTEXT_LENGTH = "16384";
      # For AMD Ryzen 7 PRO hardware, uncomment parameter below.
      # To adjust value, see command result of: nix-shell -p "rocmPackages.rocminfo" --run "rocminfo" | grep "gfx"
      # used to be necessary, but doesn't seem to anymore
      #HCC_AMDGPU_TARGET = "gfx1103";
    };
    # May require overriding if rocm does not detect your AMD GPU. 
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
