# tests/virtualisation-podman.nix
# This test verifies the installation and configuration of Podman from 'virtualisation.nix'.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-virtualisation-podman-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/virtualisation.nix ];

    config = {
      curios.virtualisation = {
        enable = true;
        docker.enable = false; # Disable Docker to avoid conflicts
        podman.enable = true;
        wine.enable = false;
      };

      # Required for many NixOS tests
      time.timeZone = "UTC";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_service_socket(service_name: str):
        machine.wait_for_unit(f"{service_name}.socket")
        machine.succeed(f"systemctl is-active {service_name}.socket")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-podman-packages"):
        check_which("podman")

    with subtest("check-podman-user-and-group"):
        machine.succeed("getent group podman")

    with subtest("check-podman-socket"):
        check_service_socket("podman")
  '';
}
