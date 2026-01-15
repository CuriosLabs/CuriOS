# Curi*OS* modules

Activate or deactivate modules by modifying `settings.nix` file:
`sudo nano /etc/nixos/settings.nix` and then rebuild nixos: `sudo nixos-rebuild switch`

```bash
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
        # NodeJS (npm, npx) JavaScript runtime
        javascript.enable = false;
        # bun JavaScript runtime
        javascript.bun.enable = false;
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
      # OBS, Audacity, DaVinci Resolve, Darktable
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
        # CRM web apps
        crm = {
          # SalesForce web app - edit baseUrl to your company SalesForce URL.
          salesforce = {
            enable = lib.mkDefault false;
            baseUrl = lib.mkDefault "your-domain.my.salesforce.com";
          };
          hubspot = {
            enable = lib.mkDefault false;
            baseUrl = "app.hubspot.com";
          };
        };
        finance = {
          gnucash.enable = false;
        };
        # Projects management apps.
        projects = {
          basecamp = {
            enable = true;
            baseUrl = "launchpad.37signals.com/signin";
          };
          # Jira web app - edit baseUrl to your company Jira URL.
          jira = {
            enable = false;
            baseUrl = "mycompany.atlassian.net";
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
        # Cursor AI-assisted IDE desktop app, cursor-agent CLI.
        cursor.enable = false;
        # Google Gemini CLI - BETTER to install it with npm, see docs/ai-tools.md
        gemini.enable = false;
        # Grok web app
        grok.enable = true;
        # lmstudio.ai local AI model
        lmstudio.enable = true;
        # Mistral LeChat web app
        mistral.enable = true;
        # Windsurf AI-assisted IDE desktop app.
        windsurf.enable = false;
      };
      chat = {
        # Discord desktop app
        discord.enable = false;
        # Signal.org desktop app
        signal.enable = true;
        # TeamSpeak6 desktop app
        teamspeak.enable = false;
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
        # LocalSend - Cross-platform file sharing on your local network
        localsend.enable = true;
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
```
