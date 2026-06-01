# Plan: Hardware-backed Secret Service Replacement for YubiKey + U2F Users

## Context & Problem

When `curios.security.u2f.enable = true` is active:

- `pam_u2f` is configured with `control = "sufficient"` on `cosmic-greeter`, `login`, `sudo`, etc.
- Authentication can succeed using only the YubiKey (no password ever collected in the PAM stack).
- COSMIC implicitly enables `services.gnome.gnome-keyring.enable = true`.
- `gnome-keyring` (via `pam_gnome_keyring.so` + `gcr-prompter`) expects the user's login password to unlock the default "login" keyring.
- Result: after successful U2F login on cosmic-greeter, a password prompt from `gcr-prompter` appears on the COSMIC desktop asking to unlock the keyring.

This is expected behavior when mixing passwordless/sufficient hardware auth with a password-derived keyring. It was observed and reported during initial testing of the U2F module (see security.nix and related discussion).

## Current State in CuriOS (as of 2026)

- `modules/security.nix` provides `curios.security.u2f.*` options (enable + lockOnRemove).
- `modules/services.nix` contains a comment noting that COSMIC forces gnome-keyring on (and that ssh-agent cannot coexist with it).
- `modules/desktop-apps/basics.nix` already ships `pkgs.keepassxc` behind `curios.desktop.utility.keepassxc.enable`.
- `yubikey-manager` and `yubioath-flutter` are unconditionally installed in basics.
- No current mechanism to disable or replace gnome-keyring's Secret Service role.
- Hardened profiles (`modules/hardened/*.nix`) use `~@keyring` in SystemCallFilter in several places — this may conflict with alternative keyring daemons.
- COSMIC Epoch 1.0.14 (released 26 May 2026) switched the default secret portal to **oo7** via `xdg-desktop-portal-cosmic#311`. See:
  - https://github.com/pop-os/cosmic-epoch/releases/tag/epoch-1.0.14
  - https://github.com/pop-os/xdg-desktop-portal-cosmic/pull/311
  YubiKey / FIDO2 integration in oo7 remains immature or undocumented as of mid-2026.

## Proposed Solution

Use **KeePassXC as the Secret Service provider** (`org.freedesktop.secrets`) instead of (or in addition to) gnome-keyring, with the KeePassXC database itself protected by the YubiKey via Challenge-Response (HMAC-SHA1 slot) + optional strong passphrase.

KeePassXC:
- Fully implements the Freedesktop Secret Service API.
- Has first-class, reliable YubiKey support (Challenge-Response is the recommended path; FIDO2/HMAC-Secret also possible).
- Allows a dedicated database or group for system/application secrets (separate from the user's main password vault).
- Works on Wayland / COSMIC without the GNOME-specific prompter issues that plague gnome-keyring.
- One portable, auditable, encrypted file instead of opaque `~/.local/share/keyrings`.

This approach is widely recommended in the Arch Wiki, KeePassXC discussions, and Pop!_OS/COSMIC communities for exactly this YubiKey + non-GNOME desktop combination.

## Why KeePassXC Over Alternatives

| Option                          | YubiKey Quality      | Secret Service | Maturity on COSMIC | Notes |
|--------------------------------|----------------------|----------------|--------------------|-------|
| gnome-keyring (current)        | Poor                 | Yes            | Default (flaky)    | Password-derived unlock breaks with U2F sufficient auth |
| oo7 (COSMIC default since 1.0.14) | Unknown / weak    | Yes            | Good (2026+)       | Primary sources: cosmic-epoch 1.0.14 + xdg-desktop-portal-cosmic#311. YubiKey support immature. |
| KeePassXC + Secret Service     | Excellent            | Yes (native)   | Works today        | Best practical choice right now |
| pass + pass-secret-service     | Excellent (via GPG)  | Yes (via daemon) | Works            | More minimal/CLI; higher setup cost |
| Bitwarden (desktop, already in CuriOS) | Excellent     | No (easy local daemon) | Good            | Great complement, not a full keyring replacement |

## Technical Background: Secret Service, xdg.portal, and gnome-keyring

This section documents the moving parts involved when trying to move away from the traditional GNOME keyring toward more modern or hardware-friendly secret storage (oo7, KeePassXC as Secret Service, etc.). It is intended as reference material for future experiments (see note at the end of this section).

### The Freedesktop Secret Service API

Applications (browsers, VPN clients, password managers, Electron apps, etc.) store and retrieve secrets through the **Secret Service API** (`org.freedesktop.secrets` on D-Bus). Any process that implements this interface can act as a "keyring".

Historically, `gnome-keyring-daemon` has been the default implementation on GNOME-based desktops (including COSMIC until recently).

### The Role of xdg-desktop-portal

Modern desktops use **XDG Desktop Portals** to mediate privileged operations (file chooser, screen capture, secret storage, etc.) in a sandbox-friendly way.

For secrets, there is a specific portal interface: `org.freedesktop.impl.portal.Secret`.

- `xdg-desktop-portal` itself does not store secrets.
- It delegates to a **backend** (also called a portal implementation).
- The backend can be `gnome-keyring`, `kwallet`, **oo7-portal**, or others.

On COSMIC, the relevant package is `xdg-desktop-portal-cosmic`. This package is responsible for telling the portal system which secret backend to use.

### How COSMIC Currently Enables gnome-keyring

In CuriOS, `modules/cosmic.nix` does:

```nix
services.desktopManager.cosmic.enable = true;
```

This module (from nixpkgs) transitively enables `services.gnome.gnome-keyring.enable = true`. This is why the comment exists in `modules/services.nix:261-263`:

> "Cosmic already set services.gnome.gnome-keyring.enable to true - cannot run both."

Because COSMIC pulls it in, simply setting the option to `false` without `lib.mkForce` has no effect. The commented line in the file already shows the correct pattern:

```nix
# services.gnome.gnome-keyring.enable = lib.mkForce false;
```

Disabling it also has side effects on:
- PAM integration (`pam_gnome_keyring.so`)
- The GCR SSH agent (`gcr-ssh-agent`)
- Auto-unlocking behavior at login

### What is oo7?

**oo7** (https://github.com/linux-credentials/oo7) is a modern, Rust-based implementation of the Secret Service specification. It was created to provide a DE-agnostic, memory-safe alternative to gnome-keyring and KWallet.

Key components (available as separate packages in nixpkgs):
- `oo7` — main library
- `oo7-server` — the daemon implementing `org.freedesktop.secrets`
- `oo7-portal` — the XDG portal backend (`org.freedesktop.impl.portal.Secret`)

In May 2026, COSMIC Epoch 1.0.14 made `oo7-portal` the default secret backend via `xdg-desktop-portal-cosmic#311`. This is the change that made COSMIC "use oo7".

### Why "disable gnome-keyring + install oo7" is not enough

Simply doing:

```nix
services.gnome.gnome-keyring.enable = lib.mkForce false;
environment.systemPackages = [ pkgs.oo7-server pkgs.oo7-portal ];
```

is **insufficient** to replicate COSMIC 1.0.14 behavior for several reasons:

1. **Portal wiring is missing** — `xdg-desktop-portal-cosmic` must be configured (via its own data files or NixOS `xdg.portal` options) to actually select `oo7-portal` as the implementation for the Secret interface.
2. **No high-level NixOS module yet** — As of mid-2026, there is no convenient `services.oo7.enable` or similar. Manual systemd user service + portal configuration is usually required.
3. **Service activation & D-Bus ownership** — The daemon must claim the bus name before other clients try to use it. Timing and socket activation matter.
4. **SSH agent conflict** — Disabling gnome-keyring also removes `gcr-ssh-agent`. An alternative must be provided if SSH agent functionality is needed.
5. **PAM and login integration** — Some auto-unlock behavior that previously came from `pam_gnome_keyring` will be lost unless something else is wired.

This is why community reports on COSMIC + NixOS often still keep gnome-keyring enabled even after the 1.0.14 release, or do careful manual configuration.

### Relevance to YubiKey + U2F Users

For users of `curios.security.u2f.enable`, the core pain point is that gnome-keyring's "login" keyring is designed to be unlocked with the user's password at PAM authentication time. When `pam_u2f` succeeds with `control = "sufficient"`, no password is available for gnome-keyring to use.

Moving the secret backend to something that:
- Can be unlocked with a YubiKey (Challenge-Response or FIDO2)
- Is not tightly coupled to the login password

...is the real goal. Both **oo7** (once it gains good hardware key support) and **KeePassXC as Secret Service** are candidates. The latter currently has much more mature YubiKey integration.

### Guidance for Future Experiments

When testing this area on a dedicated branch, consider the following checklist:

- What version of `xdg-desktop-portal-cosmic` is being used? Does it already contain the oo7 preference from PR #311?
- How to properly configure `xdg.portal` (or override portal config files) to select oo7-portal?
- What happens to SSH agent functionality after disabling gnome-keyring?
- Impact on Flatpak applications and Electron "safeStorage" APIs.
- Interaction with the existing hardened modules (several of which filter `@keyring` syscalls).
- Whether cosmic-greeter or the COSMIC session has any hard dependency on gnome-keyring still being present.

This topic is closely related to the YubiKey authentication work and should be explored together with potential improvements to `curios.security.u2f.*` options.

## High-Level Integration Goals

1. Make it easy (and safe) for users who enable U2F to also switch their secret storage to a YubiKey-protected KeePassXC database.
2. Avoid conflicts between gnome-keyring and KeePassXC over the Secret Service bus name.
3. Provide clear documentation and (eventually) automation or guided setup.
4. Respect existing hardened profiles and not regress security.
5. Do not force the change on all users — it should remain opt-in for power users with hardware keys.

## Proposed Implementation Phases (to be revisited)

### Phase 0 – Documentation (this PLAN.md)
- [x] Capture the problem, research, and proposed direction.
- [ ] Add a short warning / known limitation note in `modules/security.nix` (u2f.enable description).

### Phase 1 – User-Facing Documentation & Guidance
- Add a dedicated section in `docs/` (e.g. `docs/security-yubikey.md` or extend `system-management.md`).
- Document the manual migration path:
  - Enable `curios.desktop.utility.keepassxc.enable`
  - Configure YubiKey Challenge-Response slot (`ykman otp chalresp`)
  - Enable Secret Service Integration in KeePassXC
  - Mask `gnome-keyring-daemon.socket` (and related units)
  - D-Bus service file for autostart if needed
  - Testing with `secret-tool`, browsers, libsecret clients, etc.
- Document interaction with `curios.security.u2f.lockOnRemove`.
- **Dotfiles integration (curios-dotfiles repo)**: Prepare pre-configured KeePassXC files in `~/Projets/CuriosLabs/curios-dotfiles/` so users get Secret Service integration out of the box. Main candidates:
  - `.config/keepassxc/keepassxc.ini` (with `EnableSecretService=true`, `SecretServiceConfirmAccess=false`, etc.)
  - D-Bus activation file (`~/.local/share/dbus-1/services/org.freedesktop.secrets.service`)
  - Possible autostart entry and helper scripts (e.g. YubiKey Challenge-Response setup).
  This is user-level configuration and complements (does not replace) system Nix modules.

### Phase 2 – Optional Automation / Smoother UX (under `curios.security.u2f`)
Possible new options (names to be bikeshedded):
- `curios.security.u2f.keyringBackend` = "gnome" | "keepassxc" | "none"
- Or a dedicated `curios.security.keyring.enableKeePassXC` + conflict handling.
- Automatically mask gnome-keyring units when the KeePassXC backend is selected.
- Provide a sensible default KeePassXC autostart + D-Bus activation.
- Handle the hardened `@keyring` syscall filter interaction (either document the incompatibility or provide an escape hatch).

### Phase 3 – Deeper Integration (future)
- Possibly ship a small `curios-keyring-setup` helper or script (similar spirit to curios-install / curios-manager).
- Consider a dedicated "secrets" KeePassXC database template for system use.
- Evaluate long-term migration toward oo7 once it gains proper YubiKey/FIDO2 support.
- Update tests (`tests/`) to cover the new backend path.
- Update `modules.json` UI descriptions if a new top-level toggle appears.

## Technical Gotchas & Considerations

- **DBus name ownership**: KeePassXC will refuse to provide the secret service if gnome-keyring (or another provider) already owns `org.freedesktop.secrets`. Masking the socket is usually required.
- **PAM interaction**: `pam_gnome_keyring` may still be pulled in. We may need to explicitly remove it from relevant PAM services when switching backends.
- **SSH agent**: gnome-keyring also provides an SSH agent. Users switching away may need an alternative (e.g. `gcr-ssh-agent` selectively, or `ssh-agent` user service, or KeePassXC's own SSH agent features).
- **Electron / Chromium Safe Storage**: Some apps have hardcoded expectations. KeePassXC works for most, but a few may need `--password-store=gnome-libsecret` flags or early manual unlock.
- **Hardened profiles**: Blocking `@keyring` syscalls will likely break any keyring daemon. This needs explicit documentation or conditional logic.
- **Flatpak / sandboxing**: YubiKey access and D-Bus secret service exposure can be trickier inside Flatpaks.
- **Backup / recovery**: Emphasize that the KeePassXC file + YubiKey (or recovery codes) becomes the new root of trust for secrets.

## Open Questions (for later discussion)

- Should we ever make KeePassXC the *default* keyring backend for users who enable U2F?
- Do we want to support multiple simultaneous secret service providers, or enforce a single one?
- How do we handle the transition for existing CuriOS users who already have data in the gnome login keyring?
- Should `curios.security.u2f` imply or suggest a "hardware-first" keyring posture?
- Long-term: when oo7 matures with good FIDO2/YubiKey support, should we prefer it over KeePassXC for COSMIC purity?

## References & Research

### Primary sources for oo7 in COSMIC
- COSMIC Epoch 1.0.14 release notes: https://github.com/pop-os/cosmic-epoch/releases/tag/epoch-1.0.14  
  (explicitly lists "Use oo7-portal as secret portal by default" under xdg-desktop-portal-cosmic)
- xdg-desktop-portal-cosmic PR #311: https://github.com/pop-os/xdg-desktop-portal-cosmic/pull/311  
  ("data: Use oo7-portal as secret portal" – commit message notes GNOME & KDE moving away from gnome-keyring/kwallet)
- oo7 project (Rust Secret Service implementation): https://github.com/linux-credentials/oo7

### Other references
- Arch Wiki – KeePass (Secret Service section)
- KeePassXC GitHub discussions on Secret Service + YubiKey
- Pop!_OS / COSMIC GitHub issues around gnome-keyring flakiness on cosmic-greeter (pre-oo7)
- Existing CuriOS files:
  - `modules/security.nix`
  - `modules/services.nix` (gnome-keyring comment)
  - `modules/desktop-apps/basics.nix` (keepassxc option)
  - `modules/hardened/*.nix` (keyring syscall filters)
  - `modules.json` (utility.keepassxc toggle)

---

**Status**: Captured for future work. Do not implement yet unless explicitly requested.

**Next steps when resuming**: Review this document, decide on scope for Phase 1 (documentation only vs light automation), and validate the manual KeePassXC + YubiKey flow on a real CuriOS system with U2F enabled.