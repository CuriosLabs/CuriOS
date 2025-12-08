# tests/crypto-all-options.nix
# This is a test that enables every option in the 'crypto.nix' module
# to ensure they can all be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-crypto-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/crypto.nix ];

    # Enable all options from the 'crypto.nix' module.
    config = {
      # Some crypto software might be unfree.
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      # Enable the crypto module and all its sub-options
      curios.desktop.apps.crypto = {
        enable = true;
        btc.enable = true;
      };
    };
  };

  # Test script to verify all corresponding packages are installed and configured.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    def check_webapp(app_name: str):
        machine.succeed(f"test -f /run/current-system/sw/share/applications/{app_name}.desktop")

    with subtest("check-unconditional-crypto-apps"):
        # These are webapps that should always be installed when crypto.enable is true
        check_webapp("com.coingecko.btc")
        check_webapp("space.mempool")

    with subtest("check-btc-apps"):
        check_which("bisq2")
        check_which("electrum")
        check_which("sparrow-desktop")

    with subtest("check-udev-rules"):
        # Check if the custom udev rules for hardware wallets have been added
        machine.succeed("grep -q '1a86' /etc/udev/rules.d/99-local.rules") # Blockstream Jade
        machine.succeed("grep -q '2c97' /etc/udev/rules.d/99-local.rules") # Ledger
        machine.succeed("grep -q '1209' /etc/udev/rules.d/99-local.rules") # Trezor
  '';
}
