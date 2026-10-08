# tests/pkgs-all.nix
# This test enables all custom packages from ./pkgs/ and theirs modules
# to ensure they can be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-pkgs-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/desktop-apps/basics.nix
      ../modules/desktop-apps/crypto.nix
      ../modules/desktop-apps/devops.nix
      ../modules/desktop-apps/engineering.nix
      ../modules/desktop-apps/office.nix
      ../modules/platforms/default.nix
      ../modules/curios.nix
      ../modules/cosmic.nix
      ../modules/system.nix
    ];

    config = {
      system.stateVersion = "26.05";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [ "electron-41.10.7" ];
      time.timeZone = "UTC";

      curios = {
        desktop = {
          basics.enable = true;
          #appImage.enable = true;
          ai.lmstudio = {
            enable = true;
            bionic = true;
          };
          crypto = {
            enable = true;
            btc.enable = true;
          };
          devops = {
            enable = true;
            tui.herdr.enable = true;
          };
          engineering = {
            enable = true;
            opencad-studio.enable = true;
          };
          office = {
            enable = true;
            projects.basecamp.cli = true;
          };
        };
        system = {
          enable = true;
          core = {
            dotfiles = true;
            manager-applet = true;
          };
          hostname = "machine";
        };
      };
    };
  };

  # Test script to verify all corresponding packages are installed.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-pkgs-apps"):
        check_which("basecamp")
        check_which("curios-dotfiles")
        check_which("curios-manager")
        check_which("curios-manager-applet")
        check_which("curios-update")
        check_which("electrum")
        check_which("herdr")
        check_which("lm-studio")
        check_which("lms")
        check_which("lm-studio-bionic")
        check_which("opencadstudio")
  '';
}
