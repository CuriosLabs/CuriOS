# Virtualisation related apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.virtualisation = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enabling virtualisation app: QEMU/KVM - virt-manager.";
      };
      docker.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Docker containers + docker-compose, docker-buildx, lazydocker.";
      };
      podman.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Podman containers tool + podman-compose, podman-tui, podman-desktop.";
      };
      k3s = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description =
            "k3s lightweight Kubernetes + kubectl, helm, k9s, kustomize, cri-tools (crictl).";
        };
        disable = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "traefik" ];
          example = [ "traefik" "servicelb" "metrics-server" ];
          description = ''
            k3s built-in components to disable.
            Common values: "traefik", "servicelb", "metrics-server", "local-storage".
            Disabling traefik is recommended if installing ingress-nginx or another controller.
          '';
        };
        extraFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "--disable-network-policy" "--flannel-backend=host-gw" ];
          description =
            "Extra flags passed to k3s (e.g. for networking or feature tweaks).";
        };
      };
      wine.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Wine 32 and 64 bits with Wayland support.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.virtualisation.enable {
    virtualisation = {
      # Docker
      # See https://wiki.nixos.org/wiki/Docker for more settings.
      docker = {
        enable = lib.mkDefault config.curios.virtualisation.docker.enable;
        # dockerd needs apparmor_parser on its PATH to load the "docker-default"
        # profile at container start. Without it, containers run unconfined
        # despite docker inspect reporting the profile name.
        extraPackages =
          lib.optional config.security.apparmor.enable pkgs.apparmor-parser;
      };
      # Podman
      containers.enable =
        lib.mkDefault config.curios.virtualisation.podman.enable;
      podman = {
        enable = lib.mkDefault config.curios.virtualisation.podman.enable;
        dockerCompat = true;
        dockerSocket.enable = false;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings = { dns_enabled = true; };
      };
      # QEMU + KVM + virt-manager
      # See: https://nixos.wiki/wiki/Libvirt
      # Reboot and type this command:
      # sudo virsh net-start default && sudo virsh net-autostart default
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };
    };

    # Docker + AppArmor on NixOS requires two workarounds:
    #
    # 1. containerd's apparmor.HostSupports() hardcodes /sbin/apparmor_parser
    #    (os.Stat, not PATH lookup) to detect whether AppArmor is available.
    #    NixOS has no /sbin, so the check always fails and dockerd never loads
    #    the "docker-default" profile — containers run unconfined silently.
    #
    # 2. dockerd's macroExists() checks /etc/apparmor.d/tunables/global via
    #    os.Stat to decide whether to add #include <tunables/global> to the
    #    docker-default template. NixOS's linkFarm doesn't link tunables/
    #    from the apparmor-profiles package, so the check fails and the
    #    template falls back to @{PROC}=/proc/ — but abstractions/base still
    #    references @{HOMEDIRS}, causing a parse error. We add tunables/global
    #    to security.apparmor.includes (which writes to the linkFarm at build
    #    time) so macroExists() passes; the parser then resolves the full
    #    tunables/ tree from the apparmor-profiles package on its Include path.
    systemd.tmpfiles.rules = lib.optional config.security.apparmor.enable
      "L+ /sbin/apparmor_parser - - - - ${pkgs.apparmor-parser}/bin/apparmor_parser";

    security.apparmor.includes =
      lib.optionalAttrs config.security.apparmor.enable {
        "tunables/global" = ''
          include "${pkgs.apparmor-profiles}/etc/apparmor.d/tunables/global"
        '';
      };

    # k3s - lightweight Kubernetes for local development
    # Kubeconfig is written to /etc/rancher/k3s/k3s.yaml
    # Typical developer usage after enabling:
    #   mkdir -p ~/.kube
    #   sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    #   sudo chown $USER ~/.kube/config
    # Or use: KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl ...
    services.k3s = lib.mkIf config.curios.virtualisation.k3s.enable {
      enable = true;
      role = "server";
      disable = config.curios.virtualisation.k3s.disable;
      extraFlags =
        lib.concatStringsSep " " config.curios.virtualisation.k3s.extraFlags;
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
      enable = lib.mkDefault config.curios.virtualisation.wine.enable;
      winbindd.enable = lib.mkDefault config.curios.virtualisation.wine.enable;
      nsswins = lib.mkDefault config.curios.virtualisation.wine.enable;
    };

    environment.systemPackages = with pkgs;
      [
        # QEMU + KVM + virt-manager
        virt-manager
        # Optional: QEMU support of different arch
        qemu-user

        # WinApps missing dependencies - https://github.com/winapps-org/winapps/tree/main
        dialog
        freerdp
        netcat
      ] ++ lib.optionals config.curios.virtualisation.docker.enable [
        # Docker
        docker-buildx
        docker-compose
        lazydocker
        # YAML linters and parser
        yamllint
        yq
        # Store creds with pass (gnupg required)
        # echo '{ "credStore": "pass" }' >> $HOME/.docker/config.json
        # gpg --generate-key
        # pass init dxxxxxxxxxx@xxxxxxxxxx.com
        # pass insert docker-credential-helpers/docker-pass-initialized-check
        # echo $GH_TOKEN | docker login ghcr.io -u dxxxxxxxxxxx@xxxxxxxxx.com --password-stdin
        # cat ~/.docker/config.json
        docker-credential-helpers
        pass
      ] ++ lib.optionals config.curios.virtualisation.podman.enable [
        podman-compose
        podman-desktop
        podman-tui
        # TODO: test toolbox
      ] ++ lib.optionals config.curios.virtualisation.k3s.enable [
        # k3s + essential developer tooling
        k3s
        kubectl
        kubernetes-helm
        k9s
        kustomize
        cri-tools
      ] ++ lib.optionals config.curios.virtualisation.wine.enable [
        wineWow64Packages.waylandFull
        winetricks
        wineWow64Packages.fonts
      ];
  };
}
