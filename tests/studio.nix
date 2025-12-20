# tests/studio-all-options.nix
# This test enables all options in the 'studio.nix' module
# to ensure they can be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-studio-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/studio.nix ];

    config = {
      # DaVinci Resolve is an unfree package
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      curios.desktop.apps.studio.enable = true;
    };
  };

  # Test script to verify all corresponding packages are installed.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-studio-apps"):
        check_which("obs")
        check_which("audacity")
        check_which("davinci-resolve")
        check_which("darktable")
  '';
}
