# For small quick tests of a small batch programms

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-quick-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/devops.nix ];

    config = {
      system.stateVersion = "26.05";
      # Allow unfree packages for JetBrains IDEs etc.
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [ "electron-41.10.7" ];
      time.timeZone = "UTC";

      curios.desktop.devops = {
        enable = true;
        terminal = {
          alacritty.enable = true;
          ghostty.enable = true;
        };
        tui = {
          herdr.enable = true;
          opencode.enable = true;
        };
      };
    };
  };

  # Test script to verify all corresponding packages are installed and available.
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    # Helper function to check if a command exists in the PATH
    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-terminals"):
        check_which("alacritty")
        check_which("ghostty")

    with subtest("check-tui"):
        check_which("herdr")
        check_which("opencode")
  '';
}
