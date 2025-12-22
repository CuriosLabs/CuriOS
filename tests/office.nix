# tests/office-all-options.nix
# This is a test that enables every option in the 'office.nix' module
# to ensure they can all be installed and configured correctly.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-office-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/office.nix ];

    # Enable all options from the 'office.nix' module.
    config = {
      # Allow unfree packages for Obsidian, Zoom, etc.
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      curios.desktop.apps.office = {
        enable = true;
        libreoffice.enable = true;
        onlyoffice.desktopeditors.enable = true;
        thunderbird.enable = true;
        crm = {
          salesforce.enable = true;
          hubspot.enable = true;
        };
        projects = {
          basecamp.enable = true;
          basecamp.baseUrl = "launchpad.37signals.com/signin";
          jira.enable = true;
          jira.baseUrl = "my-company.atlassian.net";
        };
        conferencing = {
          slack.enable = true;
          teams.enable = true;
          zoom.enable = true;
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

    def check_webapp(app_name: str):
        machine.succeed(f"test -f /run/current-system/sw/share/applications/{app_name}.desktop")

    with subtest("check-default-office-apps"):
        check_which("obsidian")
        check_which("joplin-desktop")

    with subtest("check-office-suites"):
        check_which("libreoffice")
        check_which("onlyoffice-desktopeditors")

    with subtest("check-email-client"):
        check_which("thunderbird")

    with subtest("check-crm-webapps"):
        check_webapp("com.salesforce")
        check_webapp("com.hubspot")

    with subtest("check-project-management-webapps"):
        check_webapp("com.basecamp")
        check_webapp("net.atlassian.jira")

    with subtest("check-conferencing-apps"):
        check_webapp("com.slack.app")
        check_webapp("com.microsoft.teams")
        check_which("zoom")
  '';
}
