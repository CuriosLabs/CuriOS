# tests/curios.nix
# This test verifies the installation and configuration of custom CuriOS core.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-core-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/cosmic.nix ../modules/curios.nix ];
    config = {
      system.stateVersion = "26.05";
      curios.cosmic.enable = true;
      time.timeZone = "UTC";
      users.users.nixos = {
        isNormalUser = true;
        description = "Test User";
        home = "/home/nixos";
      };
    };
  };

  # Test script to verify packages and systemd user units.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-curios-packages"):
        check_which("curios-manager")
        check_which("curios-update")
        check_which("snitch")
  '';
}
