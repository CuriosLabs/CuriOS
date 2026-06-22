# tests/platform-aarch64.nix
# Platform compatibility test for aarch64-linux (RPI4)
# This test evaluates the CuriOS modules on aarch64-linux and reports
# any packages that are not available on that platform.
# It helps identify x86_64-only packages that need platform guards.
#
# Run with: nix-build ./tests/platform-aarch64.nix --show-trace

{ pkgs ? import <nixpkgs> { system = "aarch64-linux"; }, lib ? pkgs.lib }:

let
  # Build a minimal NixOS configuration with all CuriOS modules enabled
  nixos = import <nixpkgs/nixos> {
    system = "aarch64-linux";
    configuration = { config, pkgs, lib, ... }: {
      # Import CuriOS modules (excluding filesystems, hardened)
      imports = [
        ../modules/desktop-apps/default.nix
        ../modules/backup.nix
        ../modules/boot-efi.nix
        ../modules/cosmic.nix
        ../modules/curios-pkgs.nix
        ../modules/fonts.nix
        ../modules/hardware/amd-gpu.nix
        ../modules/hardware/intel-gpu.nix
        ../modules/hardware/laptop.nix
        ../modules/hardware/nvidia-gpu.nix
        ../modules/networking.nix
        ../modules/others.nix
        ../modules/security.nix
        ../modules/services.nix
        ../modules/system.nix
        ../modules/virtualisation.nix
        ../modules/zsh.nix
        ../modules/platforms/rpi4.nix
      ];

      # Minimal required NixOS settings
      boot.loader.grub.device = "nodev";
      fileSystems."/" = {
        device = "/dev/null";
        fsType = "ext4";
      };
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";
      networking.hostName = "test-aarch64";
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";

      # Enable all CuriOS options
      curios = {
        desktop = {
          basics.enable = true;
          appImage.enable = true;
          browser = {
            brave.enable = true;
            chromium.enable = true;
            firefox.enable = true;
            librewolf.enable = true;
            vivaldi.enable = true;
          };
          vpn = {
            proton.enable = true;
            tailscale.enable = true;
            mullvad.enable = true;
          };
          ai = {
            chatgpt.enable = true;
            claude.enable = true;
            cursor.enable = true;
            gemini.enable = true;
            grok.enable = true;
            lmstudio.enable = true;
            mistral.enable = true;
          };
          chat = {
            discord.enable = true;
            signal.enable = true;
            teamspeak.enable = true;
            whatsapp.enable = true;
          };
          music = {
            strawberry.enable = true;
            spotify.enable = true;
          };
          utility = {
            bitwarden.enable = true;
            flameshot.enable = true;
            keepassxc.enable = true;
            localsend.enable = true;
          };
          crypto = {
            enable = true;
            btc.enable = true;
          };
          devops = {
            enable = true;
            cloudflared.enable = true;
            editor = {
              default.nvim.enable = true;
              go.enable = true;
              java.enable = true;
              opencode.enable = true;
              python.enable = true;
              rust.enable = true;
              zed.enable = true;
              vscode.enable = true;
            };
            terminal = {
              alacritty.enable = true;
              ghostty.enable = true;
            };
            just.enable = true;
            networks.enable = true;
            tui.opencode.enable = true;
          };
          gaming = {
            enable = true;
            heroic.enable = true;
            retroarchFree.enable = true;
            steam = {
              enable = true;
              bigpicture.autoStart = true;
            };
          };
          office = {
            enable = true;
            calibre.enable = true;
            libreoffice.enable = true;
            onlyoffice.desktopeditors.enable = true;
            thunderbird.enable = true;
            crm = {
              salesforce.enable = true;
              hubspot.enable = true;
            };
            erp.odoo.enable = true;
            finance.gnucash.enable = true;
            projects = {
              basecamp = {
                enable = true;
                cli = true;
              };
              jira.enable = true;
            };
            conferencing = {
              slack.enable = true;
              teams.enable = true;
              zoom.enable = true;
            };
          };
          studio = {
            enable = true;
            davinci-resolve.enable = true;
            davinci-resolve-studio.enable = true;
            mpv.enable = true;
          };
        };
        system = {
          enable = true;
          ansible.enable = true;
          languages = {
            go.enable = true;
            java.enable = true;
            javascript = {
              enable = true;
              bun.enable = true;
            };
            python312.enable = true;
            python313.enable = true;
            ruby.enable = true;
            rust.enable = true;
          };
        };
        services = {
          enable = true;
          ollama.enable = true;
          printing.enable = true;
          sshd.enable = true;
          n8n.enable = true;
        };
        platform.rpi4.enable = true;
      };
    };
  };

  # Get all packages from the evaluated configuration
  allPackages = nixos.config.environment.systemPackages;

  # Check which packages are not available on aarch64-linux
  isUnavailable = pkg: !(lib.meta.availableOn pkgs.stdenv.hostPlatform pkg);

  unavailablePkgs = builtins.filter isUnavailable allPackages;

  # Get package names for reporting
  getName = pkg: pkg.name or pkg.pname or "<unknown>";
  unavailableNames = map getName unavailablePkgs;

  # Create a report
  reportText = ''
    Platform Compatibility Test for aarch64-linux (RPI4)
    ======================================================

    ${
      toString (builtins.length unavailablePkgs)
    } packages are NOT available on aarch64-linux:
    ${builtins.concatStringsSep "\n  - " ([ "" ] ++ unavailableNames)}

    ${if builtins.length unavailablePkgs > 0 then ''
      ERROR: These packages need platform guards (e.g., !config.curios.platform.rpi4.enable)
             in their respective modules to prevent installation on RPI4.
    '' else ''
      SUCCESS: All packages are available on aarch64-linux.
    ''}
  '';

in pkgs.runCommand "platform-aarch64-test" { } ''
  cat <<'EOF' > $out
  ${reportText}
  EOF

  ${if builtins.length unavailablePkgs > 0 then ''
    echo "=== aarch64-linux Compatibility Issues ==="
    cat $out
    exit 1
  '' else ''
    echo "=== aarch64-linux Compatibility OK ==="
    cat $out
  ''}
''
