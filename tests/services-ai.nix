# tests/services-ai.nix
# This test enables the 'services-ai.nix' module to ensure Ollama and Open-WebUI
# are correctly installed and configured.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-services-ai-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/services-ai.nix
      ../modules/hardware/amd-gpu.nix
      ../modules/hardware/nvidia-gpu.nix
    ];

    config = {
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";
      curios = {
        services.ai.enable = true;
        # Disable GPU options to ensure CPU mode is used for Ollama
        hardware.amdGpu.enable = false;
        hardware.nvidiaGpu.enable = false;
      };
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_service_active(service_name: str):
        machine.wait_for_unit(f"{service_name}.service")
        machine.succeed(f"systemctl is-active {service_name}.service")

    def check_port_listening(port: int):
        machine.succeed(f"nc -z 127.0.0.1 {port}")

    def check_desktop_file(file_name: str):
        machine.succeed(f"test -f /run/current-system/sw/share/applications/{file_name}.desktop")

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

