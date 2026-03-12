# Getting Started with Curi*OS*

This guide will help you get started with installing and using Curi*OS*.

## Prerequisites

- A machine capable of running NixOS. Any modern Intel or AMD x86-64/AMD64 CPU
  with a UEFI boot system should suffice, and any motherboard sold within the
  last 10-15 years should be compatible. A machine with at least 8Gb of RAM and
  an SSD is recommended.
- Basic understanding of [NixOS](https://wiki.nixos.org/wiki/NixOS_Wiki) concepts
is a plus.
- A USB stick to burn the Curi*OS* ISO on. You can use the [Balena Etcher](https://etcher.balena.io/#download-etcher)
  program if you are on a Windows machine, or on a Linux machine you can use
  [caligula](https://github.com/ifd3f/caligula) or the command `dd`.
- An internet connection will be required during the installation. It is
  recommended to use an Ethernet cable for this operation. If you can only use
  Wi-Fi, please note that the ISO does not include `NetworkManager`; therefore, you
  will have to manually set up the connection with [nmtui](https://man.archlinux.org/man/nmtui.1).
- Curi*OS* does not support Secure Boot/TPM for the moment. You may have to turn
  it off in the UEFI menu of your PC.

## Dual Booting with Windows

If you intend to use Curi*OS* alongside Windows, it is strongly recommended to
install each operating system on a **separate disk (SSD/NVMe)**. Dual-booting on
a single disk is not recommended and can lead to bootloader complications.

To switch between operating systems, you should use your motherboard's UEFI boot
menu at startup. This is typically accessed by pressing a shortcut key like **F8**,
**F11**, or **F12** (or sometimes **F2**) depending on your manufacturer.

During the Curi*OS* installation, the installer will list all detected disks and
ask you to choose the target for the installation. Ensure you select the empty or
dedicated disk and not the one containing your Windows installation.

## Installation

The primary method for installing Curi*OS* is by using a bootable ISO image.

> [!WARNING]
> The installation script will **FORMAT** your disk!!! Back up your data beforehand.

1. **Download the ISO**: from the [official GitHub repository](https://github.com/CuriosLabs/CuriOS/releases).

   ```bash
   wget --content-disposition https://github.com/CuriosLabs/CuriOS/releases/download/25.11.5/CuriOS_25.11.5_amd64_intel.iso
   ```

   Download and check ISO signature:

   ```bash
   wget --content-disposition https://github.com/CuriosLabs/CuriOS/releases/download/25.11.5/CuriOS_25.11.5_amd64_intel.iso.sha256
   sha256sum --check CuriOS_*.iso.sha256
   ```

2. **Flash the ISO**: You can flash it to a USB drive using tools like [Etcher](https://etcher.balena.io/#download-etcher)
   OR on Linux you can try with `caligula`:

   ```bash
   caligula burn -s $(cat ./CuriOS_25.11.5_amd64_intel.iso.sha256)
   ```

   OR with `dd`:

   ```bash
   # First step is to find your USB disk path with `fdisk`; it will probably
   # be `/dev/sda` or `/dev/sdb`.
   # Be sure that the model and size descritption match your USB key.
   sudo fdisk -l
   ```

   ```bash
   # And then to copy the ISO to the USB, `/dev/sda` in below case, adjust accordingly.
   sudo dd if=CuriOS_25.11.5_amd64_intel.iso of=/dev/sda bs=10MB oflag=dsync status=progress
   ```

3. **Boot from USB**: Boot your machine from the USB drive. You will probably
   need to hit the F8 or F12 key during your computer's startup; refer to your
   motherboard manufacturer's instructions.
   ![CuriOS installation boot](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Install_dialog_0.png?raw=true "CuriOS installation boot")
4. **Run the installer**: The installer should start automatically, or use the
   `sudo curios-install` script provided in the live environment.
   ![CuriOS installation auto-start](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Install_dialog_0b.png?raw=true "CuriOS installation start")
5. **Follow on-screen instructions**: Use the Up/Down arrow keys to move the cursor,
   the Space bar to select, Enter to validate your choice, and Tab to move between
   forms and buttons.
   ![CuriOS installation - language selection ](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Install_dialog_1.png?raw=true "CuriOS installation language selection")
   ![CuriOS installation - disk encryption](https://github.com/CuriosLabs/CuriOS/blob/release/25.11.5/img/Install_dialog_4b.png?raw=true "CuriOS installation disk encryption")
   GPU hardware (Nvidia, AMD) will be automatically detected and installed. Once
   the installation is finished, you will be invited to reboot. Do not forget to
   remove the USB stick once your computer has restarted.

For more advanced configurations and troubleshooting, please refer to the
[NixOS documentation](https://nixos.org/manual/nixos/stable/) and [NixOS Wiki](https://nixos.wiki/wiki/Main_Page).

---
**Next**: After installation, you can now [explore the Curi*OS* system](first-steps.md).

**Back**: [index](index.md).
