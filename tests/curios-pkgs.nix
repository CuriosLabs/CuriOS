# tests/curios-pkgs.nix
# This test verifies the installation and configuration of custom CuriOS packages.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-pkgs-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/curios-pkgs.nix ];
    users.users.test-user = { isNormalUser = true; };
  };

  # Test script to verify packages and systemd user units.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-curios-packages"):
        check_which("curios-dotfiles")
        check_which("curios-manager")
        check_which("curios-update")

    with subtest("check-systemd-user-units"):
        # Check if the systemd user unit files exist
        machine.succeed("test -f /etc/systemd/user/curios-updater.timer")
        machine.succeed("test -f /etc/systemd/user/curios-updater.service")
  '';
}
