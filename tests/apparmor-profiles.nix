# tests/apparmor-profiles.nix
# Test AppArmor profiles for unprivileged user namespace restriction.
# Verifies that ANSSI R45 + ruleUsernsRestrict + apparmor-profiles module
# correctly loads the unprivileged_userns transition profile and the
# NixOS-path profile for Brave.
#
# NOTE: The sysctls kernel.apparmor_restrict_unprivileged_userns and
# kernel.apparmor_restrict_unprivileged_unconfined are available on
# kernel >= 7.1 (merged into mainline in Feb 2026). On older kernels
# they don't exist and the exploit path test is skipped. On kernels
# >= 7.1 the full test including the exploit path verification runs.

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-apparmor-profiles-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/hardened/anssi-reinforced.nix
      ../modules/hardened/apparmor-profiles.nix
      ../modules/desktop-apps/basics.nix
      ../modules/platforms/default.nix
      ../modules/virtualisation.nix
    ];

    config = {
      nixpkgs.config.allowUnfree = true;
      time.timeZone = "UTC";

      curios = {
        # Enable ANSSI reinforced rules: AppArmor + userns restriction
        hardened = {
          anssi.reinforced = {
            enable = true;
            rule45 = true;
            ruleUsernsRestrict = true;
          };
          # Enable NixOS-path AppArmor profiles for sandboxed apps
          apparmor-profiles.enable = true;
        };
        # Enable Brave (the app we are testing the profile for)
        desktop = {
          basics.enable = true;
          browser = {
            brave.enable = true;
            # Disable other browsers/apps to keep the test focused
            chromium.enable = false;
            firefox.enable = false;
            librewolf.enable = false;
            vivaldi.enable = false;
          };
        };
      };

      # Create a test user for unprivileged userns test
      users.users.testuser = {
        isNormalUser = true;
        password = "test";
      };

      # Ensure tools for the exploit path test are available
      environment.systemPackages = with pkgs; [
        apparmor-bin-utils
        apparmor-utils
        iproute2
        util-linux
      ];
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("apparmor.service")

    with subtest("check-apparmor-in-lsm-stack"):
      # Check via sysfs since aa-status may not work in all test environments
      lsm_runtime = machine.succeed("cat /sys/kernel/security/lsm").strip()
      machine.log(f"runtime /sys/kernel/security/lsm: {lsm_runtime}")
      assert "apparmor" in lsm_runtime
      assert lsm_runtime.count("apparmor") == 1

    with subtest("check-lsm-nixos-option"):
      # Print the evaluated NixOS option to verify no duplicate "apparmor"
      lsm_option = machine.succeed("nixos-option security.lsm 2>/dev/null || true").strip()
      machine.log(f"nixos-option security.lsm:\n{lsm_option}")

    with subtest("check-apparmor-profiles-dir"):
      # The AppArmor securityfs must be mounted and list profiles
      machine.succeed("test -d /sys/kernel/security/apparmor")
      profiles = machine.succeed("cat /sys/kernel/security/apparmor/profiles 2>/dev/null || true").strip()
      machine.log(f"loaded profiles:\n{profiles}")
      assert len(profiles) > 0

    with subtest("check-brave-installed"):
      machine.succeed("which brave")

    with subtest("check-unprivileged-userns-profile-loaded"):
      # The transition profile that strips CAP_NET_ADMIN from unconfined userns
      profiles = machine.succeed("cat /sys/kernel/security/apparmor/profiles").strip()
      assert "unprivileged_userns" in profiles

    with subtest("check-brave-profile-loaded"):
      # The NixOS-path profile that grants userns to Brave
      profiles = machine.succeed("cat /sys/kernel/security/apparmor/profiles").strip()
      assert "nixos-brave" in profiles

    with subtest("check-brave-profile-path-glob"):
      # The profile file should contain the NixOS store path glob.
      # Use -F for fixed-string match (the * is a literal glob char, not regex)
      machine.succeed("grep -Fq '/nix/store/*-brave-*/bin/brave' /etc/apparmor.d/nixos-brave")
      # The actual brave binary path should match the glob pattern
      brave_path = machine.succeed("readlink -f $(which brave)").strip()
      assert "/nix/store/" in brave_path
      assert brave_path.endswith("/bin/brave")
      machine.succeed(f"test -f {brave_path}")

    with subtest("check-brave-profile-has-userns-permission"):
      # The profile must grant userns so Brave's sandbox works under restriction
      machine.succeed("grep -q 'userns' /etc/apparmor.d/nixos-brave")

    with subtest("check-userns-restriction-sysctls"):
      # These sysctls require kernel >= 7.1 (merged into mainline Feb 2026).
      # On older kernels they don't exist - log and skip.
      sysctl_exists = machine.succeed("test -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns && echo yes || echo no").strip()
      if sysctl_exists == "yes":
        val = machine.succeed("sysctl -n kernel.apparmor_restrict_unprivileged_userns").strip()
        machine.log(f"kernel.apparmor_restrict_unprivileged_userns = {val}")
        assert val == "1"
        val2 = machine.succeed("sysctl -n kernel.apparmor_restrict_unprivileged_unconfined").strip()
        machine.log(f"kernel.apparmor_restrict_unprivileged_unconfined = {val2}")
        assert val2 == "1"
      else:
        machine.log("SKIP: kernel.apparmor_restrict_unprivileged_userns sysctl not available (requires kernel >= 7.1)")

    with subtest("check-exploit-path-blocked"):
      # An unprivileged user should NOT be able to get CAP_NET_ADMIN via userns.
      # This is the exact path used by CVE-2026-46331 (pedit COW) and
      # CVE-2026-43503 (DirtyClone) exploits.
      # Only runs if the AppArmor userns restriction sysctls are present
      # (kernel >= 7.1).
      sysctl_exists = machine.succeed("test -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns && echo yes || echo no").strip()
      if sysctl_exists == "yes":
        machine.fail("su -l testuser -c 'unshare -Urn -- ip link add dum0 type dummy'")
      else:
        machine.log("SKIP: exploit path test requires AppArmor userns restriction sysctls (requires kernel >= 7.1)")
  '';
}
