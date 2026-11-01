# CuriOS NixOS AppArmor profiles — main entry point.
#
# This directory mirrors the structure of /etc/apparmor.d/:
#   abstractions.nix  → security.apparmor.includes  (abstractions/curios/*, abstractions/electron, …)
#   profiles/         → security.apparmor.policies  (one file per application)
#   options.nix       → curios.hardened.apparmor-profiles.* NixOS options
#
# Useful commands:
# `nixos-option security.lsm`, `aa-enabled`, `sudo aa-status`
# `eza -l -tree /etc/apparmor.d/`
# `sudo aa-status` `sudo aa-status --complaining`
# sudo grep "apparmor=\"DENIED\"" /var/log/audit/audit.log | grep -i brave
# sudo grep -E "apparmor=\"(ALLOWED|DENIED|ERROR)\"" /var/log/audit/audit.log
# sudo grep -E 'apparmor="(STATUS|ERROR)"' /var/log/audit/audit.log
# sudo grep -E 'seccomp|SECCOMP' /var/log/audit/audit.log
# sudo grep -E 'op=capable|capname=' /var/log/audit/audit.log | grep -iE 'sys_admin|sys_chroot|setuid|setgid'
# Clear AppArmor change when debugging:
# `sudo fd -d 1 . /var/cache/apparmor/ -E logprof -x rm -rf {} && sudo systemctl restart apparmor`
# Get current AppArmor profile mode of an app:
# `curios-update --nixos-option curios.hardened.apparmor-profiles.desktop.browsers.brave.mode`
# Change an AppArmor profile mode:
# `sudo curios-update --update-module curios.hardened.apparmor-profiles.desktop.browsers.brave.mode "complain" && sudo curios-update --update`
#
# TODO: Add AppArmor profiles in priority order:
#   Tier 1 — Chromium/Electron (render untrusted network content):
#     - cursor (Electron IDE)
#   Tier 1 — Document viewers (PDF is turing-complete: JS, fonts, 3D;
#            long CVE history; files arrive from email/web):
#     - okular / zathura (PDF viewers)
#   Tier 1 — Email clients (render HTML mail, parse MIME, open
#            attachments — classic malware delivery vector):
#     - thunderbird / geary
#   Tier 2 — Media players / codec & image parsers (codec parsing is a
#            historic buffer-overflow goldmine; e.g. CVE-2023-4863 WebP hit
#            nearly every Linux image library):
#     - mpv / ffmpeg-backed tools / image viewers
#   Tier 2 — Thumbnailers / file managers (opening a folder of untrusted
#            files silently invokes parsers for every format — a file manager
#            without a profile indirectly exposes every thumbnailer):
#     - nautilus / thunar / COSMIC files
#   Tier 2 — Archive extraction tools (zip bombs, path traversal, symlink
#            attacks — extraction runs parsers on untrusted structure):
#     - file-roller / ark
#   Tier 3 — Native editors with WebView (access SSH keys/tokens/source):
#     - zed
#   Tier 3 — Flutter/non-Electron apps with network + filesystem access:
#     - localsend
#
# TUI/CLI tools (curios-manager, nvim) do NOT need profiles — they operate on
# explicit user input, have dynamic filesystem access, and minimal attack
# surface. Profile maintenance cost outweighs security benefit.
#
# OpenCode TUI IS profiled (cli.opencode, profiles/opencode.nix) because it is
# an AI agent with arbitrary shell access: the LLM can be prompt-injected to
# exfiltrate secrets. AppArmor is the only real boundary — opencode's own
# tool-level path filtering is trivially bypassed (cp to /tmp, symlinks, /proc,
# alternate paths, etc.).
# Package managers (Nix) are already sandboxed by design.
#
# References:
# https://github.com/roddhjav/apparmor.d/tree/main/apparmor.d
# https://wiki.debian.org/AppArmor/HowToUse
# https://hedgedoc.grimmauld.de/s/hWcvJEniW#
# https://hedgedoc.grimmauld.de/s/03eJUe0X3#
# https://wiki.archlinux.org/title/AppArmor

{ ... }: {
  imports = [ ./options.nix ./abstractions.nix ./profiles/default.nix ];
}
