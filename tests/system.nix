# tests/system.nix
# This test verifies the 'system.nix' module, specifically the Ansible installation.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-system-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/system.nix ];

    # Enable the system module and ansible.
    config = {
      curios.system = {
        enable = true;
        ansible.enable = true;
        # Use 'machine' to avoid conflict with NixOS test driver node name
        hostname = "machine";
        i18n.locale = "en_US.UTF-8";
        keyboard = "us";
        timeZone = "UTC";
      };
    };
  };

  # Test script to verify the corresponding package is installed.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-ansible-installed"):
        check_which("ansible")
        check_which("ansible-playbook")

    with subtest("check-system-settings"):
        # Check if the hostname was set
        machine.succeed("hostname | grep -q 'machine'")
  '';
}
