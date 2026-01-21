# tests/others.nix
# This test enables the 'others.nix' module to ensure it can be installed correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-other-system-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/others.nix ];

    # Enable the others module.
    config = {
      time.timeZone = "UTC";
      curios.others = {
        enable = true;
        openssl.enable = true;
      };
    };
  };

  # Test script to verify the corresponding package is installed.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-other-system"):
        check_which("htop")
        check_which("openssl")
  '';
}
