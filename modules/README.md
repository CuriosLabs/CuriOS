# Curi*OS* modules

Activate or deactivate modules by modifying `settings.nix` file: `sudo nano /etc/nixos/settings.nix` and then rebuild nixos: `sudo nixos-rebuild switch`

```bash
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
```
