# tests/cosmic.nix
# This test enables the 'cosmic.nix' module to ensure it can be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-cosmic-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/cosmic.nix ];

    # Enable the COSMIC module.
    config = {
      curios.desktop.cosmic.enable = true;
      time.timeZone = "UTC";
    };
  };

  # Test script to verify all corresponding packages are installed and services are running.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    def check_service(service_name: str):
        machine.wait_for_unit(f"{service_name}.service")
        machine.succeed(f"systemctl is-active {service_name}.service")

    with subtest("check-cosmic-packages"):
        check_which("jq")
        check_which("lld")
        check_which("lswt")
        check_which("xdg-settings")
        check_which("cosmic-applets")
        check_which("cosmic-comp")
        check_which("cosmic-greeter")
        check_which("cosmic-osd")
        check_which("cosmic-session")

    with subtest("check-cosmic-services"):
        # The 'cosmic-greeter' service should be running.
        # 'cosmic-desktop' itself doesn't run as a systemd service in the same way,
        # but the greeter is a good indicator that the session would start correctly.
        check_service("cosmic-greeter-daemon")
  '';
}
