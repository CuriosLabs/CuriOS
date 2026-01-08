# tests/basics-all-options.nix
# This is a comprehensive test that enables every option in the 'basics.nix' module
# to ensure they can all be installed in the same system without conflict.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-basics-all-options-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/desktop-apps/basics.nix ];

    # Enable all options from the 'basics.nix' module.
    # This also implicitly tests the default values for webapps etc.
    config = {
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      curios.desktop.apps = {
        basics.enable = true;
        appImage.enable = true;

        # Browsers
        browser = {
          chromium.enable = true;
          firefox.enable = true;
          librewolf.enable = true;
          vivaldi.enable = true;
        };

        # VPNs
        vpn = {
          proton.enable = true;
          tailscale.enable = true;
          mullvad.enable = true;
        };

        # AI Apps
        ai = {
          chatgpt.enable = true;
          claude.enable = true;
          cursor.enable = true;
          gemini.enable = true;
          grok.enable = true;
          lmstudio.enable = true;
          mistral.enable = true;
        };

        # Chat Apps
        chat = {
          discord.enable = true;
          signal.enable = true;
          teamspeak.enable = true;
          whatsapp.enable = true;
        };

        # Utilities
        utility = {
          bitwarden.enable = true;
          flameshot.enable = true;
          keepassxc.enable = true;
          localsend.enable = true;
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

    # Helper function to check for webapp .desktop files
    def check_webapp(app_name: str):
        # Webapps are installed as .desktop files in the system's application directory
        machine.succeed(f"test -f /run/current-system/sw/share/applications/{app_name}.desktop")

    with subtest("check-browsers"):
        check_which("chromium")
        check_which("firefox")
        check_which("librewolf")
        check_which("vivaldi")
        check_which("brave") # This one is installed unconditionally by basics.enable

    with subtest("check-vpn-clients"):
        check_which("protonvpn-app")
        check_which("tailscale")
        check_which("mullvad-vpn")

    with subtest("check-ai-apps"):
        check_webapp("com.chatgpt")
        check_webapp("ai.claude.chats")
        check_which("cursor")
        check_which("cursor-agent")
        check_which("gemini") # Executable for gemini-cli
        check_webapp("ai.x.grok")
        check_which("lm-studio")
        #check_which("lms") # LM Studio CLI
        check_webapp("ai.mistral.chat")

    with subtest("check-chat-apps"):
        check_which("Discord")
        check_which("signal-desktop")
        check_which("TeamSpeak")
        check_webapp("com.whatsapp.web")

    with subtest("check-utilities"):
        check_which("bitwarden")
        check_which("flameshot")
        check_which("keepassxc")
        check_which("localsend_app")

    with subtest("check-unconditional-basics"):
        check_which("alacritty")
        check_which("vlc")
        check_which("gimp")
        check_which("tldr")
        check_which("procs")
  '';
}
