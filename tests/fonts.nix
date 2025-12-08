# tests/fonts.nix
# This test enables the 'fonts.nix' module to ensure fonts are installed and recognized by fontconfig.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-fonts-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/fonts.nix
      ../modules/cosmic.nix
    ];

    config = {
      curios.fonts.enable = true;
      # Enable cosmic to include conditional fonts
      curios.desktop.cosmic.enable = true;
      time.timeZone = "UTC"; # Required for many NixOS tests
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    # Function to check if a font is listed by fc-list
    def check_font_present(font_name: str):
        machine.succeed(f"fc-list | grep -q '{font_name}'")

    with subtest("check-font-installation"):
        check_font_present("DejaVu")
        check_font_present("Awesome")
        check_font_present("JetBrains")
        check_font_present("Fira")
        check_font_present("Emoji")
        check_font_present("Noto")
        check_font_present("OpenSans")
  '';
}
