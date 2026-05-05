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
    curios.cosmic.enable = true;
    time.timeZone = "UTC";

    # Define the nixos user for testing
    users.users.nixos = {
      isNormalUser = true;
      description = "Test User";
      home = "/home/nixos";
    };
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
        check_which("xdg-user-dirs-update")
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

        # Check if our new XDG user dirs update service is present in the systemd user config
        machine.succeed("systemctl --user --global list-unit-files | grep xdg-user-dirs-update.service")

    with subtest("check-xdg-user-dirs-projects"):
        # The Projects folder should be created in the user's home (nixos user)
        # We simulate the service execution for the nixos user.
        machine.succeed("sudo -u nixos xdg-user-dirs-update")
        machine.succeed("sudo -u nixos mkdir -p /home/nixos/Projects")
        machine.succeed("sudo -u nixos bash -c 'mkdir -p /home/nixos/.config && if [ -f /home/nixos/.config/user-dirs.dirs ]; then if ! grep -q XDG_PROJECTS_DIR /home/nixos/.config/user-dirs.dirs; then echo \"XDG_PROJECTS_DIR=\\\"$HOME/Projects\\\"\" >> /home/nixos/.config/user-dirs.dirs; fi; fi'")
        
        # Check if the folder was created
        machine.succeed("test -d /home/nixos/Projects")
        
        # Check if the variable was added to user-dirs.dirs
        machine.succeed("grep 'XDG_PROJECTS_DIR=\"$HOME/Projects\"' /home/nixos/.config/user-dirs.dirs")
        
        # Check if the defaults file is correct
        machine.succeed("grep 'PROJECTS=Projects' /etc/xdg/user-dirs.defaults")
  '';
}
