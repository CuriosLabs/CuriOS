# tests/backup.nix
# This test enables the 'backup.nix' module to ensure it can be installed correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-backup-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/backup.nix ];

    # Enable the backup module.
    config = {
      curios.backup.enable = true;
    };
  };

  # Test script to verify the corresponding package is installed.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-backup-app"):
        check_which("restic")
  '';
}
