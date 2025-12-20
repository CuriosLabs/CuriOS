# tests/services.nix
# This test verifies the installation and configuration of core CuriOS services.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-services-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/curios-options.nix
      ../modules/services.nix
      ../modules/cosmic.nix
    ];

    config = {
      curios = {
        # Enable all services for comprehensive testing
        services = {
          enable = true;
          printing.enable = true;
          sshd.enable = true;
        };

        desktop.cosmic.enable = true;

        # Set a keyboard layout to satisfy the xserver dependency
        system.keyboard = "us";
      };

      # Required for many NixOS tests
      time.timeZone = "UTC";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_service_active(service_name: str):
        machine.wait_for_unit(f"{service_name}.service")
        machine.succeed(f"systemctl is-active {service_name}.service")

    def check_file_exists(path: str):
        machine.succeed(f"test -f {path}")

    with subtest("check-system-services"):
        check_service_active("sshd")
        #check_service_active("cups")
        #check_service_active("rtkit-daemon")

    #with subtest("check-flatpak-configuration"):
        # The flatpak-repo service should add these remotes
        #machine.succeed("flatpak remotes | grep -q 'flathub'")
        #machine.succeed("flatpak remotes | grep -q 'cosmic'")

    with subtest("check-user-units"):
        check_file_exists("/etc/systemd/user/flatpak-update.service")
        check_file_exists("/etc/systemd/user/flatpak-update.timer")
        check_file_exists("/etc/systemd/user/pipewire.service")

    with subtest("check-keyboard-layout"):
        # Check that the xkb layout configuration was written correctly
        check_file_exists("/etc/X11/xorg.conf.d/00-keyboard.conf")
        machine.succeed("grep '\"XkbLayout\" \"us\"' /etc/X11/xorg.conf.d/00-keyboard.conf")
  '';
}
