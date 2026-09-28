# tests/engineering-all-options.nix
# This test enables all options in the 'engineering.nix' module
# to ensure they can be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-engineering-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/desktop-apps/engineering.nix
      ../modules/platforms/default.nix
    ];

    config = {
      system.stateVersion = "26.05";
      time.timeZone = "UTC";

      curios.desktop.engineering = {
        blender.enable = true;
        enable = true;
        f3d.enable = true;
        freecad.enable = true;
        kicad.enable = true;
        librecad.enable = true;
        opencad-studio.enable = true;
        orca-slicer.enable = true;
      };
    };
  };

  # Test script to verify all corresponding packages are installed.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-engineering-apps"):
        check_which("blender")
        check_which("f3d")
        check_which("freecad")
        check_which("kicad")
        check_which("librecad")
        check_which("opencadstudio")
        check_which("orca-slicer")
  '';
}