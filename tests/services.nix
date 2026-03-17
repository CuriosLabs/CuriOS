# tests/services.nix
# This test verifies the installation and configuration of core CuriOS services.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-services-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/curios-options.nix
      ../modules/hardware/amd-gpu.nix
      ../modules/hardware/intel-gpu.nix
      ../modules/hardware/nvidia-gpu.nix
      ../modules/services.nix
      ../modules/cosmic.nix
    ];

    config = {
      nixpkgs.config.allowUnfree = true;
      curios = {
        # Enable all services for comprehensive testing
        services = {
          enable = true;
          printing.enable = true;
          sshd.enable = true;
          ollama.enable = true;
        };

        cosmic.enable = true;

# Disable GPU options to ensure CPU mode is used for Ollama
         hardware = {
           amdGpu.enable = false;
           intelGpu.enable = false;
           nvidiaGpu.enable = false;
         };

        # Set a keyboard layout to satisfy the xserver dependency
        system.keyboard = "us";
      };

      # Required for many NixOS tests
      time.timeZone = "UTC";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_service_active(service_name: str):
        machine.wait_for_unit(f"{service_name}.service")
        machine.succeed(f"systemctl is-active {service_name}.service")

    def check_file_exists(path: str):
        machine.succeed(f"test -f {path}")

    def check_port_listening(port: int):
        machine.succeed(f"nc -z 127.0.0.1 {port}")

    def check_desktop_file(file_name: str):
        machine.succeed(f"test -f /run/current-system/sw/share/applications/{file_name}.desktop")

    with subtest("check-system-services"):
        check_service_active("sshd")
        #check_service_active("cups")
        #check_service_active("rtkit-daemon")

    #with subtest("check-flatpak-configuration"):
        # The flatpak-repo service should add these remotes
        #machine.succeed("flatpak remotes | grep -q 'flathub'")
        #machine.succeed("flatpak remotes | grep -q 'cosmic'")

    with subtest("check-user-units"):
        check_file_exists("/etc/systemd/user/flatpak-update.service")
        check_file_exists("/etc/systemd/user/flatpak-update.timer")
        check_file_exists("/etc/systemd/user/pipewire.service")

    with subtest("check-keyboard-layout"):
        # Check that the xkb layout configuration was written correctly
        check_file_exists("/etc/X11/xorg.conf.d/00-keyboard.conf")
        machine.succeed("grep '\"XkbLayout\" \"us\"' /etc/X11/xorg.conf.d/00-keyboard.conf")

    with subtest("check-ai-services"):
        check_service_active("ollama")
        check_service_active("open-webui")

    with subtest("check-network-ports"):
        machine.wait_for_open_port(11434) # ollama
        machine.wait_for_open_port(8080)  # open-webui

    with subtest("check-desktop-app"):
        check_desktop_file("com.ollama.openwebui")
  '';
}
