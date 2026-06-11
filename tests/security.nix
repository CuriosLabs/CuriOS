# tests/security.nix
# Tests for security features including U2F and keyring provider.

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-security-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/security.nix ../modules/desktop-apps/basics.nix ];

    config = {
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      curios.security = {
        u2f = {
          enable = true;
          keyringProvider = "keepassxc";
        };
      };

      # basics needs to be enabled to reference desktop options
      curios.desktop.basics.enable = true;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    # Helper function to check if a command exists in the PATH
    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-u2f-pam-config"):
        machine.succeed("grep -q 'pam_u2f.so' /etc/pam.d/login")
        machine.succeed("grep -q 'pam_u2f.so' /etc/pam.d/sudo")

    with subtest("check-keepassxc-installed"):
        machine.succeed("which keepassxc")

    with subtest("check-security-pkgs"):
        check_which("ykman")

    with subtest("check-gnome-keyring-disabled"):
        # NixOS builds gnome-keyring with -Dsystemd=disabled, so it has
        # no systemd units in /etc/systemd/user/. It is activated via D-Bus.
        # When disabled, the D-Bus service symlinks must be absent.
        machine.fail("test -e /run/current-system/sw/share/dbus-1/services/org.gnome.keyring.service")
        machine.fail("test -e /run/current-system/sw/share/dbus-1/services/org.freedesktop.secrets.service")
  '';
}
