# Virtualisation

Curi*OS* can turn your machine into a workstation for virtual machines,
containers, and Windows compatibility. Nothing in this module is enabled by
default: turn on what you need from **Curi*OS* Manager**.

## Enable virtualisation

The parent option `curios.virtualisation.enable` installs **QEMU/KVM** and
**virt-manager**. Other tools (Docker, Podman, k3s, Wine, WinBoat) are extra
toggles on top of that.

1. Open `curios-manager` (Shortcut: `Super+Return`).
2. Go to the `Applications` menu, then `Install/uninstall CuriOS Apps` menu.
3. Search for `(curios) virtualisation`.
4. Toggle `enable`, then the options that you need (Space bar).
5. Press Enter to Save and `curios-manager` will handle the installation.

From a terminal:

```bash
sudo curios-update --update-module curios.virtualisation.enable true && \
sudo curios-update --update
```

Reboot after the first enable so KVM and libvirt groups apply to your user.

## QEMU, KVM and virt-manager

Enabled with `curios.virtualisation.enable`:

- **virt-manager**: graphical UI to create and manage virtual machines.
- **QEMU/KVM**: hardware-accelerated VMs (libvirtd).
- **SWTPM**: virtual TPM for guests that need it (Windows 11, etc.).
- **qemu-user** and **binfmt**: run and build for other architectures
  (aarch64 is configured by default).

After the first reboot, start the default libvirt network once:

```bash
sudo virsh net-start default && sudo virsh net-autostart default
```

> [!NOTE]
> After a libvirt update followed by `nix-collect-garbage`, an existing VM may
> fail to start. In virt-manager, open the VM XML, remove the `<loader>` and
> `<nvram>` lines, then apply. virt-manager will recreate them.

## Docker

Enable `curios.virtualisation.docker.enable`. This installs:

- **Docker** engine, **docker-compose**, **docker-buildx**
- **lazydocker** TUI (desktop shortcut: `Super+Alt+D`)
- **yamllint**, **yq**

Prefer **rootless Docker** unless your images need to run with `--privileged`.
Rootless runs the daemon as your user (data in `~/.local/docker`) and avoids a
system-wide Docker daemon. Enable it with:

```bash
sudo curios-update --update-module curios.virtualisation.docker.enable true && \
sudo curios-update --update-module curios.virtualisation.docker.rootless true && \
sudo curios-update --update
```

> [!WARNING]
> Do **NOT** enable Docker and Podman at the same time.

To build multi-architecture images with buildx:

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name container-builder --driver docker-container --bootstrap --use
```

## Podman

Enable `curios.virtualisation.podman.enable`. This installs:

- **Podman** (Docker-compatible CLI)
- **podman-compose**, **podman-desktop**, **podman-tui**

DNS is enabled on the default Podman network so compose stacks can talk to
each other. The Docker socket compatibility layer is off, so this does not
conflict with a Docker install — still prefer one engine or the other.

## k3s (local Kubernetes)

Enable `curios.virtualisation.k3s.enable` for a single-node Kubernetes cluster
plus developer tools: **kubectl**, **helm**, **k9s**, **kustomize**, **crictl**.

Traefik is disabled by default so you can install another ingress later.
Override `curios.virtualisation.k3s.disable` or `curios.virtualisation.k3s.extraFlags`
if you need different components.

Kubeconfig is written to `/etc/rancher/k3s/k3s.yaml`. Copy it for your user:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER" ~/.kube/config
kubectl get nodes
```

Or use it in place: `KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes`.

## Windows apps: Wine and WinBoat

- **Wine** (`curios.virtualisation.wine.enable`): Wine 32/64-bit with Wayland,
  winetricks, fonts, plus Samba (`ntlm_auth` / winbind) for apps that need it.

```bash
sudo curios-update --update-module curios.virtualisation.wine.enable true && \
sudo curios-update --update
```

- **WinBoat** (`curios.virtualisation.winboat.enable`): run Windows applications
  on Linux with seamless desktop integration. See the
  [WinBoat website](https://winboat.app/) for documentation and the FAQ.

WinBoat needs **Docker** or **Podman**. If you use Docker, it must be the
**non-rootless** daemon (`curios.virtualisation.docker.rootless` left `false`).

From a terminal:

```bash
sudo curios-update --update-module curios.virtualisation.enable true && \
sudo curios-update --update-module curios.virtualisation.winboat.enable true && \
sudo curios-update --update-module curios.virtualisation.docker.enable true && \
sudo curios-update --update-module curios.virtualisation.docker.rootless false && \
sudo curios-update --update-module curios.virtualisation.podman.enable false && \
sudo curios-update --update
```

You can edit the compose files by hand to add extra options (USB passthrough,
and more — see [dockur/windows](https://github.com/dockur/windows/)):

- Docker: `~/.winboat/docker-compose.yml`
- Podman: `~/.winboat/podman-compose.yml`

## Windows apps: Bottles

[Bottles](https://usebottles.com/) is a friendly interface to run Windows
software and games on Linux. It builds on Wine and lets you manage isolated
"bottles" (environments) per application, each with its own prefixes,
dependencies, and runners.

The easiest way to install Bottles is through the **COSMIC Store** (Flatpak).
Search for `Bottles` and click Install.

From a terminal, which does the same thing:

```bash
flatpak install flathub com.usebottles.bottles
```

You can also browse communities, runners, and extensions directly on the
[Bottles App Store](https://usebottles.com/appstore).

Bottles is an alternative to the Wine and WinBoat options above: pick the tool
that fits your workflow best.

---
**Previous**: [Engineering applications](engineering.md)

**Back**: [index](index.md).
