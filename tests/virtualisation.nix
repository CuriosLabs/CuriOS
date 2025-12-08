# tests/virtualisation.nix
# This test enables the 'virtualisation.nix' module to ensure all services and packages
# are correctly installed and configured.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-virtualisation-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/virtualisation.nix ];

    config = {
      curios.virtualisation = {
        enable = true;
        docker.enable = true;
        podman.enable = false;
        wine.enable = true;
      };

      # Wine requires some unfree packages
      nixpkgs.config.allowUnfree = true;

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

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-virtualisation-packages"):
        # Docker
        check_which("docker")
        check_which("docker-compose")
        check_which("lazydocker")
        # QEMU/KVM
        check_which("virt-manager")
        check_which("qemu-kvm")
        # Wine
        check_which("wine")
        check_which("winetricks")

    with subtest("check-user-and-group-creation"):
        machine.succeed("getent group docker")

    with subtest("check-binfmt"):
        # Check if binfmt is configured for aarch64
        machine.succeed("grep -q 'aarch64' /proc/sys/fs/binfmt_misc/aarch64-linux")

    with subtest("check-virtualisation-services"):
        check_service_active("docker")
        check_service_active("libvirtd")
  '';
}
