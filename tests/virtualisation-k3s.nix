# tests/virtualisation-k3s.nix
# This test verifies the installation and basic functionality of k3s
# from the 'virtualisation.nix' module.
# k3s is a lightweight Kubernetes distribution aimed at developers.
# See: https://nlewo.github.io/nixos-manual-sphinx/development/writing-nixos-tests.xml.html
# See: https://wiki.nixos.org/wiki/NixOS_VM_tests

import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "curios-virtualisation-k3s-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/virtualisation.nix ];

    config = {
      # k3s + containerd + etcd/sqlite need a decent amount of memory to start reliably in CI
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 4096;

      curios.virtualisation = {
        enable = true;
        docker.enable = false; # avoid any potential port/resource conflicts
        podman.enable = false;
        k3s.enable = true;
        wine.enable = false;
      };

      # Required for many NixOS tests
      time.timeZone = "UTC";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    def check_which(pkg_name: str):
        machine.succeed(f"which {pkg_name}")

    with subtest("check-k3s-packages"):
        # Core k3s + the developer tools we install alongside it
        check_which("k3s")
        check_which("kubectl")
        check_which("helm")
        check_which("k9s")
        check_which("kustomize")
        check_which("crictl")

    with subtest("check-k3s-service"):
        machine.wait_for_unit("k3s.service")
        machine.succeed("systemctl is-active k3s.service")

    with subtest("check-kubeconfig"):
        machine.succeed("test -f /etc/rancher/k3s/k3s.yaml")

    with subtest("check-k3s-cluster-ready"):
        # Wait for the API server to become responsive.
        # We use the full KUBECONFIG path because the standalone kubectl
        # binary does not know about k3s by default.
        machine.wait_until_succeeds(
            "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes",
            timeout=180
        )
        # The single-node "machine" should report as Ready
        machine.succeed(
            "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes | grep -q Ready"
        )

    with subtest("check-k3s-basic-functionality"):
        # Basic smoke test that the cluster is actually usable
        machine.succeed(
            "KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl cluster-info"
        )
        # Also verify that the k3s binary's embedded kubectl works
        machine.succeed("k3s kubectl get nodes | grep -q Ready")
  '';
}
