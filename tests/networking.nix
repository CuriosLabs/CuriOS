# tests/networking.nix
# This test verifies the networking options configured by 'networking.nix'.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-networking-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/networking.nix ];

    config = {
      curios.networking.enable = true;
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

    with subtest("check-network-manager"):
        check_service_active("NetworkManager")
  '';
}
