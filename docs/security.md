# Security & Hardware Keys

Curi*OS* provides a complete, easy-to-use security experience built around
hardware security keys such as YubiKey.

Through the **Curi*OS* Manager**, you can manage your entire security posture
from a single menu — no manual configuration files or command-line tools needed.

The security features work together to protect your system at every stage:

- **Logging in** — use your YubiKey instead of a password at the login screen
- **Unlocking your disk** — use your YubiKey to decrypt your drive at boot time
- **Remote access** — store SSH keys securely on your YubiKey
- **Boot protection** — ensure only trusted software can start your computer
- **Application confinement** — restrict what desktop apps can access on your system

![CuriOS manager security menu](https://github.com/CuriosLabs/CuriOS/blob/testing/img/curios-manager_security2.png?raw=true "curios-manager security")

## Five Security Features at a Glance

It is important to understand that these are **independent features** you can
enable in any combination:

| Feature | When it happens | What it does | Fallback |
| --- | --- | --- | --- |
| PAM U2F (login / sudo) | After the system boots | Authenticate users and elevate privileges | Password always available |
| LUKS FIDO2 disk decryption | During early boot | Unlock the encrypted root filesystem | Strong recovery passphrase (mandatory) |
| SSH key on YubiKey | When connecting to remote servers | Use a hardware-backed key for SSH | Standard SSH keys or passwords still work |
| Secure Boot | Every time the computer starts | Blocks untrusted software from booting | Can be disabled in the firmware settings |
| AppArmor | While applications are running | Restricts what confined apps can read, write, or execute | Per-app complain mode or disable |

Enabling one does **not** automatically enable the others.

## PAM U2F Authentication

When this feature is enabled, Curi*OS* configures your system so that a
FIDO2/U2F security key can be used to authenticate.

### Key behaviors

- Authentication is configured so that a successful key touch can replace
  password entry.
- Password authentication remains available as a fallback.
- Users who do not have a key configured will not be blocked.
- Interactive prompts and visual cues are enabled for better user experience.

### Supported services

U2F authentication is enabled for:

- `cosmic-greeter` (COSMIC login screen)
- `greetd`
- `login` (console)
- `sudo`

### Multi-machine YubiKey support

By default Curi*OS* uses stable values instead of your computer's hostname.

**The goal** is to make it easy to use the *same* YubiKey enrollment across
multiple machines. When the origin and application ID are stable values instead
of per-hostname, you can share the resulting configuration file between
machines and the key will work without re-enrollment.

The **Curi*OS* Manager** automatically reads these two values when performing
U2F enrollment.

If you want different values (for example your own domain), override them in
`settings.nix`.

## Automatic Session Locking

You can optionally enable automatic session locking. When this option is active,
removing the YubiKey from the USB port will automatically lock all user
sessions. This provides a convenient physical security feature (similar to
pulling a smart card).

This option is **disabled by default** and is not available from the Curi*OS*
Manager menu. To enable it, run the following command:

```bash
sudo curios-update --update-module curios.security.u2f.lockOnRemove true && sudo curios-update --update
```

> [!NOTE]
> The `lockOnRemove` feature is very convenient but can be surprising if you
> frequently unplug your key. Test it first to make sure it fits your workflow.

## LUKS Disk Encryption with FIDO2

This feature allows you to use a FIDO2-compatible security key (such as a
YubiKey 5 or newer) to unlock your encrypted root partition at boot time.

- Curi*OS* uses the modern `systemd-cryptenroll` approach (the recommended path
  when systemd in the initrd is active).
- The key must support the FIDO2 `hmac-secret` extension (most YubiKey 5 series
  and later devices do).

### Plymouth boot splash prompt

When this feature is active, the standard Plymouth theme is used. The prompt
will usually display a generic message such as **"Enter password"**.

> [!WARNING]
> Even though the message says "Enter password", this is the prompt where you must
> enter your YubiKey PIN (if you configured one) **or** your LUKS recovery
> passphrase when FIDO2 disk decryption is enabled.

- If your YubiKey requires a client PIN, type the PIN at this prompt.
- If the key only requires a touch (no PIN), insert the key and touch it when
  the LED blinks.
- The recovery passphrase always works as a fallback at the same prompt.

> [!NOTE]
> A FIDO2-related message: "confirm presence on security token" should appear
> on the graphical splash. Touch the button / metal contact of your key.

### Critical requirement: Recovery passphrase

**You must always keep a strong recovery passphrase** for your LUKS volume.

If your YubiKey is lost, damaged, or simply not plugged in during boot, the only
way to decrypt the disk is with the recovery passphrase that was set during
installation (or added later via the manager).

Without a recovery method, a lost hardware key would result in permanent data
loss.

## SSH Key on YubiKey

You can create an SSH key that lives **inside** your YubiKey instead of as a
file on your computer. This means the private key never leaves the hardware,
making it much more resistant to theft or malware.

- The key is generated as a **resident key** stored directly on the YubiKey.
- The file on your computer is only a reference (a "handle") that tells the
  YubiKey which key to use.
- You can use the key on another machine by downloading it from the YubiKey.

### What the manager does

The Curi*OS* Manager walks you through the process:

1. **Checks your YubiKey** — it verifies that a compatible key is inserted.
2. **PIN check** — if your YubiKey does not have a FIDO2 PIN set yet, the
   manager will offer to help you create one. A PIN is required for this feature.
3. **Name your key** — you give the key a friendly name (for example,
   "work-laptop").
4. **Touch the key** — you enter your PIN and touch the YubiKey when it blinks.
5. **Done** — the key is ready to use for remote connections.

### Using the key on another machine

Because the private key is stored on the YubiKey itself, you can move to a
different computer and download the key from the device. You do not need to
carry separate key files.

To import the key on another computer, insert your YubiKey and run:

```bash
cd ~/.ssh/ && ssh-keygen -K
```

This will download the resident key from the YubiKey into the current
`~/.ssh/` directory.

### Listing credentials

The manager can also show you which SSH keys and other credentials are
currently stored on your YubiKey.

## Secure Boot

Secure Boot ensures that only trusted, properly signed software can start your
computer. It protects against malicious programs that try to modify the boot
process and quietly take control before the operating system loads.

On Curi*OS*, Secure Boot is supported through the **Limine** bootloader,
which is the default bootloader since Curi*OS* 26.05.5.

The Curi*OS* Manager provides a guided, step-by-step setup:

1. **System check** — the manager verifies your system is ready.
2. **Bootloader check** — if you are upgrading from a previous version of
   Curi*OS* that used a different bootloader, the manager will offer to switch
   to Limine, which is required for Secure Boot.
3. **Firmware check** — the manager scans your computer's firmware and will
   warn you if a firmware update is needed before Secure Boot can work.
4. **Key creation** — the manager generates the necessary security keys
   automatically.
5. **Enter Setup Mode** — the manager guides you to reboot into your computer's
   firmware settings, clear the existing security keys, and return to Curi*OS.
   > On ThinkPad devices, use **"Reset to Setup Mode"** instead of **"Clear All
   > Secure Boot Keys"**.
6. **Enroll keys** — back in Curi*OS*, the manager enrolls the new keys and
   enables Secure Boot.
7. **Final reboot** — one last restart to confirm everything works.

### Important warnings

> [!WARNING]
> Enabling Secure Boot is an **advanced operation**. Make sure you are
> comfortable with your computer's firmware settings and know how to boot into
> UEFI mode if needed. In the Limine boot menu, you can press **S** to enter the
> firmware settings directly.

> [!WARNING]
> If you run other operating systems alongside Curi*OS* (dual-boot), Secure Boot
> may prevent them from starting until their boot files are also signed. Only
> enable Secure Boot if you understand how to manage this for all your systems.

> [!WARNING]
> Always keep your LUKS recovery passphrase in a safe place. Secure Boot protects
> the boot process, but disk encryption is still your last line of defense.

## AppArmor

AppArmor is a Mandatory Access Control (MAC) system. When it is enabled, selected
desktop applications run inside a **profile** that lists what they are allowed to
do — which files they may read or write, which devices they may open, and which
other programs they may start.

This limits the damage if an application is compromised. A confined browser, for
example, cannot freely read your SSH keys or password-manager files even if a
tab is exploited.

AppArmor is **disabled by default**. Enable it from the Curi*OS* Manager
**🔐 Security** menu with **🛡️ Enable AppArmor**.

### What the manager enables

The manager turns on three related options, then applies a system update:

1. **ANSSI reinforced hardening** — the parent module required by AppArmor
   (`curios.hardened.anssi.reinforced.enable`). Other reinforced rules (IOMMU,
   module loading, sudo `noexec`) stay off unless you enable them yourself.
2. **ANSSI rule R45** — starts the AppArmor service, enables audit logging of
   program executions, and kills processes that have a profile but are running
   unconfined (`curios.hardened.anssi.reinforced.rule45`).
3. **Curi*OS* AppArmor profiles** — ships the confinement rules for supported
   desktop apps (`curios.hardened.apparmor-profiles.enable`).

After the update, the manager shows whether AppArmor is active and how many
profiles are in **enforce** or **complain** mode.

### Confined applications

| Application | Default mode | What the profile covers |
| --- | --- | --- |
| Brave | enforce | Browser, sandbox, and launcher |
| Discord | enforce | Desktop client and sandbox |
| Signal Desktop | enforce | Desktop client and sandbox |
| OnlyOffice | enforce | Desktop editors |
| Steam | complain | Steam client, Proton, and native games |

Only these applications are confined. Everything else on the system keeps its
normal permissions.

### Profile modes

Each profile can be set independently:

- **enforce** — unauthorized actions are blocked and logged.
- **complain** — unauthorized actions are allowed but still logged. Useful to
  diagnose a broken app without turning AppArmor off.
- **disable** — the profile is not loaded for that application.

Steam defaults to **complain** because games and Proton prefixes vary widely and
a strict profile would break many titles.

### If an application breaks

If a confined app cannot open a file, use a device, or start a helper after you
enable AppArmor, switch that profile to complain, then update:

```bash
sudo curios-update --update-module curios.hardened.apparmor-profiles.desktop.browsers.brave.mode "complain" && sudo curios-update --update
```

Replace the option path with the application you need:

| Application | Option |
| --- | --- |
| Brave | `curios.hardened.apparmor-profiles.desktop.browsers.brave.mode` |
| Discord | `curios.hardened.apparmor-profiles.desktop.chat.discord.mode` |
| Signal Desktop | `curios.hardened.apparmor-profiles.desktop.chat.signal-desktop.mode` |
| OnlyOffice | `curios.hardened.apparmor-profiles.desktop.office.onlyoffice.mode` |
| Steam | `curios.hardened.apparmor-profiles.desktop.gaming.steam.mode` |

To inspect denials:

```bash
sudo aa-status
sudo grep 'apparmor="DENIED"' /var/log/audit/audit.log
```

> [!WARNING]
> AppArmor is an **advanced hardening feature**. A too-strict profile can prevent
> an application from working until you switch it to complain or disable it.
> Test your usual workflow after enabling it.

> [!NOTE]
> Enabling AppArmor does not replace disk encryption, Secure Boot, or YubiKey
> authentication. It only confines the applications listed above.

## Configuration via Curi*OS* Manager

All security settings, as well as the enrollment process itself, are managed
through the **Curi*OS* Manager**.

1. Launch the manager with **Super + Return**
2. Navigate to the **🔐 Security** section

From this menu you can:

- Enroll your YubiKey for full disk decryption
- Enable Secure Boot
- Register your primary YubiKey for login and sudo
- Add an additional YubiKey for login and sudo
- View your current U2F keys
- Test PAM authentication
- Add an SSH key to your YubiKey
- List the SSH keys and credentials stored on your YubiKey
- Enable AppArmor

## Best Practices

- **Always have a recovery method** for LUKS FIDO2. Test it at least once after
  enrollment.
- Consider enrolling **two different YubiKeys** (primary + backup) for important
  machines.
- The `lockOnRemove` feature is very convenient but can be surprising if you
  frequently unplug your key. Test it first.
- U2F/PAM, LUKS FIDO2, SSH keys, Secure Boot, and AppArmor can be enabled
  independently. Choose the combination that matches your security requirements.
- After enabling AppArmor, test the confined applications you use daily. If one
  misbehaves, switch its profile to `complain` before turning AppArmor off.
- The default origin and application ID values are designed so you can use one
  YubiKey across several machines. Only change them if you have a specific reason.
- At the Plymouth boot prompt with FIDO2 active, remember you can always use the
  recovery passphrase if your key is not inserted or the PIN step is not what
  you expect.
- For SSH keys on a YubiKey, remember that the private key lives on the device.
  The local file is just a handle. If you lose the YubiKey, you cannot use that
  SSH key anymore.
- Before enabling Secure Boot, make sure you understand how to access your
  firmware settings. The Limine boot menu offers a quick shortcut (**S**) to
  enter the firmware setup.
- If you dual-boot, research how Secure Boot affects your other operating
  systems before enabling it.

---
**Next**: [Audio/Video applications](audio-video.md).

**Previous**: [AI tools](ai-tools.md)

**Back**: [index](index.md).
