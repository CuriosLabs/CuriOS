# tests/gaming-all-options.nix
# This is a test that enables every option in the 'gaming.nix' module
# to ensure they can all be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-gaming-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/gaming.nix ];

    # Enable all options from the 'gaming.nix' module.
    config = {
      # The module already forces this, but we're explicit.
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      # Enable the gaming module and all its sub-options
      curios.desktop.apps.gaming = {
        enable = true;
        #steam.bigpicture.autoStart = true;
      };
    };
  };

  # Test script to verify all corresponding packages are installed and services are running.
  testScript = ''
    start_all()
    # Wait for the system to be fully booted
    machine.wait_for_unit("multi-user.target")

    # Helper function to check if a command exists in the PATH
    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-gaming-executables"):
        check_which("steam")
        check_which("Discord")
        check_which("heroic")
        check_which("TeamSpeak")
        check_which("gamemoderun")
        check_which("steam-run")
        check_which("input-remapper-gtk")

    #with subtest("check-steam-bigpicture-autostart"):
        # The makeAutostartItem creates a desktop file in the user's autostart directory.
        # In NixOS tests, the default user is 'root'.
        #machine.succeed("test -f /root/.config/autostart/steam.desktop")
        # Verify the content of the autostart file to ensure --bigpicture is present
        #machine.succeed("grep -q 'Exec=steam --bigpicture' /root/.config/autostart/steam.desktop")
  '';
}
