# Virtualisation related apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.virtualisation.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enabling virtualisation app: docker, QEMU/KVM, virt-manager.";
    };
    curios.virtualisation.wine.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enabling Wine 32 and 64 bits with Wayland support.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.virtualisation.enable {
    # Docker
    virtualisation.docker.enable = true;
    # QEMU + KVM + virt-manager
    # See: https://nixos.wiki/wiki/Libvirt
    # Reboot and type this command:
    # sudo virsh net-start default && sudo virsh net-autostart default
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    # VMs created by virt-manager can break after a libvirt update and a nix-collect-garbage, See: https://github.com/NixOS/nixpkgs/pull/421549 https://github.com/NixOS/nixpkgs/issues/378894
    # Temp fix: in virt-manager, edit the VM's XML configuration file, suppress lines with <loader></loader> and <nvram></nvram>. Apply, virt-manager will re-create correct one.

    # Optional: QEMU support of different arch
    # Launch this 2 commands for docker build multi platform:
    #docker run --privileged --rm tonistiigi/binfmt --install all
    #docker buildx create --name container-builder --driver docker-container --bootstrap --use
    boot.binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = true; # Make it work with docker
    };

    # Samba, provide ntlm_auth, winbind, required by most Windows programs under Wine
    services.samba = {
      enable = lib.mkDefault (
        config.curios.virtualisation.wine.enable
      );
      winbindd.enable = lib.mkDefault (
        config.curios.virtualisation.wine.enable
      );
      nsswins = lib.mkDefault (
        config.curios.virtualisation.wine.enable
      );
    };

    environment.systemPackages = with pkgs; [
      # Docker
      docker-buildx
      docker-compose
      lazydocker
      # Store creds with pass (gnupg required)
      # echo '{ "credStore": "pass" }' >> $HOME/.docker/config.json
      # gpg --generate-key
      # pass init dxxxxxxxxxx@xxxxxxxxxx.com
      # pass insert docker-credential-helpers/docker-pass-initialized-check
      # echo $GH_TOKEN | docker login ghcr.io -u dxxxxxxxxxxx@xxxxxxxxx.com --password-stdin
      # cat ~/.docker/config.json
      docker-credential-helpers
      pass
      # QEMU + KVM + virt-manager
      virt-manager
      # Optional: QEMU support of different arch
      qemu-user

      # WinApps missing dependencies - https://github.com/winapps-org/winapps/tree/main
      dialog
      freerdp
      netcat
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.python312.enable [
      pkgs.python312Packages.docker
    ]
    ++ lib.optionals config.curios.virtualisation.wine.enable [
      wineWowPackages.waylandFull
      winetricks
      wineWowPackages.fonts
      wineWow64Packages.fonts
    ];
  };
}
