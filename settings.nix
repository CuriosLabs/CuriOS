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

{
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
    # Create primary groups for each users, each with an unique gid.
    groups = { nixos = { gid = 1000; }; };
    # Define a user account
    # <user> name and description will be updated by curios-install during ISO install
    users.nixos = {
      isNormalUser = true;
      initialHashedPassword = "";
      description = "My Name";
      # user's primary group name
      group = "nixos";
      # user list of auxiliary groups
      extraGroups =
        [ "users" "wheel" "audio" "sound" "video" "plugdev" "dialout" ]
        ++ lib.optionals config.curios.desktop.crypto.enable [ "tty" ]
        ++ lib.optionals config.curios.hardware.various.i2c.enable ["i2c"]
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
      # account UID
      uid = 1000;
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

  # Services
  services = {
    ### pipewire sound settings:
    pipewire = {
      extraConfig.pipewire."92-low-latency" = {
        # Keep increasing the quantum value until you get no sound crackles
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 16384;
      };
    };
    ### Ollama
    ollama = {
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

    ### n8n webhook configuration (for external services calling your workflows)
    # n8n = {
    #   environment = {
    #     # By default n8n webhooks only work from the local machine
    #     # (http://localhost:5678/webhook/... and /webhook-test/...).
    #     # This is sufficient for local testing and scripts running on the same laptop.
    #     #
    #     # To receive webhooks from external services (GitHub, Stripe, Typeform,
    #     # external APIs, etc.), n8n must know its public URL.
    #     # You need a tunnel or reverse proxy.
    #     #
    #     # Recommended easy approach on CuriOS:
    #     #   1. Enable the cloudflared client:
    #     #        curios.desktop.devops.cloudflared.enable = true;
    #     #   2. In a terminal run:
    #     #        cloudflared tunnel --url http://localhost:5678
    #     #   3. Copy the https://*.trycloudflare.com URL it prints
    #     #   4. Paste it below (keep the trailing slash!)
    #     #
    #     # Important variables:
    #     #   WEBHOOK_URL         → used for activated (production) workflows
    #     #   N8N_EDITOR_BASE_URL → used for the n8n UI and test webhooks
    #     #   N8N_PROXY_HOPS      → must be set when n8n is behind any tunnel/proxy
    #     #
    #     # After changing these values, restart n8n:
    #     #   sudo systemctl restart n8n
    #
    #     WEBHOOK_URL = "https://your-tunnel-id.trycloudflare.com/";
    #     N8N_EDITOR_BASE_URL = "https://your-tunnel-id.trycloudflare.com/";
    #     N8N_PROXY_HOPS = "1";
    #   };
    # };
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
