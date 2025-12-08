# tests/devops-all-options.nix
# This is a comprehensive test that enables every option in the 'devops.nix' module
# to ensure they can all be installed in the same system without conflict.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-devops-all-options-test";

  # Give this test more time, as it installs multiple JetBrains IDEs.

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/devops.nix ];

    # Enable all options from the 'devops.nix' module.
    config = {
      # Allow unfree packages for JetBrains IDEs etc.
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      curios.desktop.apps.devops = {
        enable = true;
        cloudflared.enable = true;
        editor = {
          default.nvim.enable = true;
          zed.enable = true;
          vscode.enable = true;
        };
        go.enable = true;
        javascript.enable = true;
        python312.enable = true;
        python313.enable = true;
        rust.enable = true;
        networks.enable = true;
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

    with subtest("check-unconditional-devops"):
        check_which("nvim")
        check_which("gh")
        check_which("whois")
        check_which("shellcheck")
        check_which("statix")
        check_which("clang")
        check_which("fd")
        check_which("fzf")
        check_which("lazygit")
        check_which("rg") # ripgrep
        check_which("yq")

    with subtest("check-cloudflared"):
        check_which("cloudflared")

    with subtest("check-editors"):
        check_which("zeditor")
        check_which("nil")
        check_which("nixd")
        check_which("code") # vscode
        # Check that nvim is the default editor
        machine.succeed("readlink -f $(which vi) | grep -q 'nvim'")
        machine.succeed("readlink -f $(which vim) | grep -q 'nvim'")

    with subtest("check-go"):
        check_which("go")
        check_which("golangci-lint")
        check_which("goland")

    with subtest("check-javascript"):
        check_which("node")
        check_which("npm")

    with subtest("check-python"):
        check_which("python3.12")
        check_which("python3.13")
        check_which("uv")
        check_which("pycharm-community")
        check_which("ruff")

    with subtest("check-rust"):
        check_which("rustup")
        check_which("cargo-cbuild")
        check_which("rust-rover")
        check_which("pkg-config")

    with subtest("check-networks"):
        check_which("nmap")
        check_which("zenmap")
        check_which("wireshark")
        check_which("remmina")
  '';
}
