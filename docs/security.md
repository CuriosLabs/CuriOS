# Security & Hardware Keys (YubiKey / FIDO2)

Curi*OS* provides first-class support for hardware security keys such as YubiKey through the `curios.security` module.

This module currently focuses on two independent but complementary features:

- **Post-boot authentication** using `pam_u2f` (login, greeter, sudo, etc.)
- **Pre-boot disk decryption** using FIDO2 for LUKS volumes

Both features can be enabled and managed directly from the **Curi*OS* Manager**.

## Two Different Security Use Cases

It is important to understand that these are **two distinct mechanisms**:

| Feature                        | When it happens     | Purpose                              | Module option                     | Fallback                  |
|--------------------------------|---------------------|--------------------------------------|-----------------------------------|---------------------------|
| PAM U2F (login / sudo)         | After the system boots | Authenticate users and elevate privileges | `curios.security.u2f.enable`     | Password always available |
| LUKS FIDO2 disk decryption     | During early boot (initrd) | Unlock the encrypted root filesystem | `curios.security.luksFido2.enable` | Strong recovery passphrase (mandatory) |

These two options are independent. Enabling one does **not** automatically enable the other.

## PAM U2F Authentication

When `curios.security.u2f.enable` is set to `true`, Curi*OS* configures `pam_u2f` so that a FIDO2/U2F security key can be used to authenticate.

### Key behaviors

- Authentication is configured with `control = "sufficient"`: a successful key touch can replace password entry.
- Password authentication remains available as a fallback.
- The `nouserok` option is enabled: users who do not have a key configured will not be blocked.
- Interactive prompts and visual cues (`cue`) are enabled for better user experience.

### Supported services

U2F authentication is enabled for:

- `cosmic-greeter` (COSMIC login screen)
- `greetd`
- `login` (console)
- `sudo`

### Automatic session locking

You can optionally enable `curios.security.u2f.lockOnRemove`. When this option is active, removing the YubiKey from the USB port will automatically lock all user sessions. This provides a convenient physical security feature (similar to pulling a smart card).

### Origin and AppID (multi-machine YubiKey support)

By default Curi*OS* configures:

```nix
curios.security.u2f = {
  origin = "curios";
  appid  = "curios";
};
```

This is different from the upstream `pam_u2f` default (`pam://$HOSTNAME`).

**The goal** is to make it easy to use the *same* YubiKey enrollment across multiple machines. When `origin` and `appid` are stable values instead of per-hostname, you can share the resulting `~/.config/Yubico/u2f_keys` file between machines and the key will work without re-enrollment.

The **Curi*OS* Manager** automatically reads these two values when performing U2F enrollment (`pamu2fcfg -o ... -i ...`).

If you want different values (for example your own domain), override them in `settings.nix`:

```nix
curios.security.u2f = {
  origin = "myname.example.com";
  appid  = "myname.example.com";
};
```

When enrolling manually, use matching flags:

```bash
pamu2fcfg -u "$USER" -o "curios" -i "curios" >> ~/.config/Yubico/u2f_keys
```

## LUKS Disk Encryption with FIDO2

The `curios.security.luksFido2.enable` option allows you to use a FIDO2-compatible security key (such as a YubiKey 5 or newer) to unlock your encrypted root partition at boot time.

### How it works

- Curi*OS* uses the modern `systemd-cryptenroll` + `crypttabExtraOpts` approach (the recommended path when `boot.initrd.systemd.enable` is active).
- The key must support the FIDO2 `hmac-secret` extension (most YubiKey 5 series and later devices do).

### Plymouth boot splash prompt

When FIDO2 LUKS decryption is enabled, Curi*OS* automatically switches to a modified Plymouth theme (`pixels-fido2`) that shows the cue **"YubiKey PIN or recovery passphrase"** instead of the generic "Enter a password".

This prevents confusion at the boot splash screen: the prompt is waiting for your hardware key's PIN (if configured) or your LUKS recovery passphrase (if the key is absent or not responding).

- If your YubiKey is configured to require a client PIN, enter it at this prompt.
- If the key only requires a touch (no PIN), you may still briefly see the prompt; insert the key and touch it when the LED blinks.
- The recovery passphrase always works as a fallback at this same prompt.

Some secondary FIDO2 messages (e.g. "confirm presence on security token") may only be visible in the initrd journal and not on the graphical splash.

### Critical requirement: Recovery passphrase

**You must always keep a strong recovery passphrase** for your LUKS volume.

If your YubiKey is lost, damaged, or simply not plugged in during boot, the only way to decrypt the disk is with the recovery passphrase that was set during installation (or added later via `systemd-cryptenroll --recovery-key`).

Without a recovery method, a lost hardware key would result in permanent data loss.

### Relationship with `u2f.enable`

The LUKS FIDO2 option is **completely separate** from the PAM U2F option. Many users enable one without the other depending on their threat model:

- Some prefer a strong passphrase for the disk and only use the YubiKey for login/sudo.
- Others want the extra physical security of requiring the key even to boot the machine.

## Configuration via Curi*OS* Manager

All YubiKey-related security settings, as well as the enrollment process itself, are managed through the **Curi*OS* Manager**.

1. Launch the manager with **Super + Return**
2. Navigate to the **󰌾 Security** section

From this menu you can:

- Enable or disable U2F authentication (`curios.security.u2f.enable`)
- Enable or disable automatic session locking on key removal
- Enable or disable FIDO2 support for LUKS disk decryption
- Enroll (or re-enroll) your security key for the chosen features

The manager reads your current `curios.security.u2f.origin` and `curios.security.u2f.appid` settings and passes them to `pamu2fcfg` during U2F enrollment (and uses the equivalent values for `systemd-cryptenroll` when enrolling for LUKS FIDO2). This ensures consistent behavior across machines.

## Best Practices

- **Always have a recovery method** for LUKS FIDO2. Test it at least once after enrollment.
- Consider enrolling **two different YubiKeys** (primary + backup) for important machines.
- The `lockOnRemove` feature is very convenient but can be surprising if you frequently unplug your key. Test it first.
- U2F/PAM and LUKS FIDO2 can be enabled independently. Choose the combination that matches your security requirements.
- `origin` and `appid` default to `"curios"`. This is the recommended value if you want to use one YubiKey across several machines. Only change them if you have a specific reason.
- At the Plymouth boot prompt with FIDO2 active, remember you can always use the recovery passphrase if your key is not inserted or the PIN step is not what you expect.

## Related Topics

- [Backups](backups.md) — Recommended even (and especially) when using hardware-backed encryption
- [System Management](system-management.md) — How to use the Curi*OS* Manager

---

**Note**: The enrollment workflow in the `󰌾 Security` menu of `curios-manager` is under active development. Check the [CuriOS GitHub repository](https://github.com/CuriosLabs/CuriOS) for the latest status.