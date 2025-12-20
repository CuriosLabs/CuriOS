# tests/zsh.nix
# This test verifies the installation and configuration of ZSH and related tools.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-zsh-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/zsh.nix ];

    config = {
      curios.shell.zsh.enable = true;
      users.users.test-user = { isNormalUser = true; };
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-zsh-packages"):
        check_which("bat")
        check_which("duf")
        check_which("dust")
        check_which("eza")
        check_which("fd")
        check_which("fzf")
        check_which("jq")
        check_which("tte")
        check_which("zoxide")
        check_which("zsh")

    with subtest("check-default-shell"):
        # Check that the default shell for a new user is zsh
        machine.succeed("getent passwd test-user | grep -q '/bin/zsh'")
  '';
}
