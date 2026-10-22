# OpenCode TUI AppArmor profile.
# Profile: opencode
#
# OpenCode is an AI coding agent with arbitrary shell access. The LLM can be
# prompt-injected to exfiltrate secrets. AppArmor is the only real boundary —
# opencode's own tool-level path filtering is trivially bypassed (cp to /tmp,
# symlinks, /proc, alternate paths, etc.).
#
# The profile confines opencode AND all child processes it spawns (bash tool,
# git, language runtimes, etc.) because AppArmor profiles are inherited by
# exec'd children unless they transition to another profile.
#
# secrets-deny blocks SSH keys, cloud credentials, wallets, .env files, .pem
# files, password managers, and crypto keys even if the agent is compromised
# via prompt injection or hallucination.

{ config, lib, pkgs, ... }:

let
  cfg = config.curios.hardened.apparmor-profiles;
  anssi = config.curios.hardened.anssi.reinforced;
in {
  config = lib.mkIf (cfg.enable && anssi.enable && anssi.rule45) {
    security.apparmor.policies = {
      "opencode" = {
        state = cfg.cli.opencode.mode;
        profile = let
          modeFlag = if cfg.cli.opencode.mode == "complain" then
            "flags=(complain, attach_disconnected)"
          else
            "flags=(attach_disconnected)";
        in ''
          abi <abi/4.0>,
          include <tunables/global>

          # OpenCode TUI — AI coding agent with shell access.
          # The profile confines opencode AND all child processes it spawns
          # (bash tool, git, language runtimes, etc.) because AppArmor profiles
          # are inherited by exec'd children unless they transition to another
          # profile. This is the real security boundary that opencode's own
          # tool-level path filtering cannot provide.
          #
          # secrets-deny blocks SSH keys, cloud credentials, wallets, .env files,
          # .pem files, password managers, and crypto keys even if the agent is
          # compromised via prompt injection or hallucination.
          #
          # Read access covers all of $HOME (including hidden dirs) so skills can
          # read arbitrary configs. Write is limited to non-hidden dirs (projects)
          # plus specific opencode/bun directories.

          profile opencode /nix/store/*-opencode-*/bin/opencode ${modeFlag} {
            include <abstractions/base>
            include <abstractions/consoles>
            include <abstractions/nameservice>
            include <abstractions/ssl_certs>
            include <abstractions/curios/secrets-deny>
            include <abstractions/curios/agents-skills>

            # Nix store: read all, exec binaries, mmap libraries.
            # On NixOS the store is world-readable by design; granting read
            # is not a meaningful security boundary (see abstractions/chromium).
            /nix/store/**                                                          r,
            /nix/store/*/bin/*                                                     rix,
            /nix/store/*/lib{,32,64}/**.so*                                        mr,
            /nix/store/*-opencode-*/bin/opencode                                   mrix,

            # NixOS system binaries (symlinks into the store)
            /run/current-system/sw/bin/*                                           rix,
            /run/current-system/sw/share/**                                        r,

            # Shell and coreutils — opencode's bash tool spawns these.
            # They inherit this profile, so secrets-deny applies to them too.
            /nix/store/*-bash-interactive-*/bin/{sh,bash}                          rix,
            /nix/store/*-coreutils-*/bin/*                                         rix,
            /nix/store/*-findutils-*/bin/*                                         rix,
            /nix/store/*-gnugrep-*/bin/grep                                        rix,
            /nix/store/*-gnused-*/bin/sed                                          rix,
            /nix/store/*-gawk-*/bin/{awk,gawk}                                     rix,
            /nix/store/*-diffutils-*/bin/*                                         rix,
            /nix/store/*-gzip-*/bin/*                                              rix,
            /nix/store/*-gnutar-*/bin/*                                            rix,
            /nix/store/*-xz-*/bin/*                                                rix,
            /nix/store/*-bzip2-*/bin/*                                             rix,
            /nix/store/*-jq-*/bin/*                                                rix,
            /nix/store/*-yq-*/bin/*                                                rix,
            /nix/store/*-curl-*/bin/*                                              rix,
            /nix/store/*-wget-*/bin/*                                              rix,

            # Git — ubiquitous in dev workflows. Note: SSH-based git remotes
            # will fail because ~/.ssh/ is denied by secrets-deny. Use HTTPS.
            # libexec/ is needed because git execs its internal helpers
            # (git-remote-https, git-upload-pack, etc.) from libexec/git-core/.
            /nix/store/*-git-*/bin/*                                               rix,
            /nix/store/*-git-*/libexec/**                                          rix,

            # Language runtimes — opencode may invoke these for project tooling
            # (linting, testing, building). All inherit this profile.
            /nix/store/*-nodejs-*/bin/*                                            rix,
            # npm-cli.js lives in lib/node_modules/npm/bin/, not bin/
            /nix/store/*-nodejs-*/lib/node_modules/npm/bin/*                       rix,
            /nix/store/*-bun-*/bin/*                                               rix,
            /nix/store/*-python3-*/bin/*                                           rix,
            /nix/store/*-rust-*/bin/*                                              rix,
            /nix/store/*-cargo-*/bin/*                                             rix,
            /nix/store/*-go-*/bin/*                                                rix,
            /nix/store/*-gcc-*/bin/*                                               rix,
            /nix/store/*-clang-*/bin/*                                             rix,
            /nix/store/*-gnumake-*/bin/*                                           rix,
            /nix/store/*-cmake-*/bin/*                                             rix,
            /nix/store/*-ninja-*/bin/*                                             rix,

            # Deliberately NOT allowed: openssh, gpg, aws, gcloud, kubectl,
            # docker, gh — these would attempt to read credentials that
            # secrets-deny blocks, causing confusing failures. If needed,
            # add them here and accept that their config reads will be denied.
            #
            # Skills, npm, and Brave browser rules are in <abstractions/curios/agents-skills>.

            # Network — LLM API calls, package registries, git over HTTPS.
            # A compromised agent could exfiltrate project source code via
            # the LLM API endpoint, but cannot read local secrets to send.
            network inet stream,
            network inet6 stream,
            network inet dgram,
            network inet6 dgram,
            network netlink raw,

            # Terminal — TUI needs /dev/pts and /dev/tty
            /dev/pts/*                                                             rw,
            /dev/tty                                                               rw,
            /dev/ptmx                                                              rw,

            # OpenCode config, cache, and data.
            # 'l' (link) needed for git hardlinks in snapshot/ (atomic pack writes).
            # 'm' (mmap) needed for cache files and git object access.
            owner @{HOME}/.config/opencode/                                        rwk,
            owner @{HOME}/.config/opencode/**                                      rwk,
            owner @{HOME}/.cache/opencode/                                         rwk,
            owner @{HOME}/.cache/opencode/**                                       rwk,
            owner @{HOME}/.local/share/opencode/                                   rwkl,
            owner @{HOME}/.local/share/opencode/**                                 rwklm,

            # OpenCode state (XDG_STATE_HOME) — model cache, history, locks.
            # 'l' (link) and 'm' (mmap) needed for atomic writes and cache files.
            owner @{HOME}/.local/state/opencode/                                   rwk,
            owner @{HOME}/.local/state/opencode/**                                 rwklm,

            # XDG state directory (~/.local/state/) — application state, locks,
            # history. Skills and tools (basecamp, etc.) create lock files here.
            # secrets-deny still blocks keyrings and other secrets.
            owner @{HOME}/.local/state/                                            rwk,
            owner @{HOME}/.local/state/**                                          rwklm,

            # OpenTUI tree-sitter grammars — WASM files for syntax highlighting.
            # OpenCode (Bun runtime) loads these for code blocks in the TUI.
            # 'w' needed because OpenTUI may download/update grammars on first use.
            owner @{HOME}/.local/share/opentui/                                   rwk,
            owner @{HOME}/.local/share/opentui/**                                 rwklm,

            # Bun runtime (~/.bun/) — package cache and binaries.
            # Bun downloads and caches npm packages here.
            owner @{HOME}/.bun/                                                    rwk,
            owner @{HOME}/.bun/**                                                  rwklm,

            # Git user config (not credentials — secrets-deny blocks
            # .git-credentials and ~/.config/git/**).
            owner @{HOME}/.gitconfig                                               r,

            # Home directory listing (path resolution, ~ expansion)
            owner @{HOME}/                                                         r,
            /home/                                                                 r,

            # .config directory listing (needed by various tools to find configs)
            owner @{HOME}/.config/                                                 r,

            # Home directory — read ALL (including hidden dirs for skills/configs),
            # write only non-hidden dirs (projects). This lets skills read arbitrary
            # config files under ~/.config/, ~/.local/, etc. without enumerating
            # every path. secrets-deny still blocks reading ~/.ssh/, ~/.gnupg/,
            # .env, *.pem, id_* keys, *.kdbx, cloud credentials, wallets, etc.
            # Write is restricted to non-hidden dirs to prevent creating backdoors
            # in ~/.ssh/ or modifying ~/.gnupg/.
            owner @{HOME}/**                                                       r,
            owner @{HOME}/[^.]*/                                                   rwk,
            owner @{HOME}/[^.]*/**                                                 rwklm,

            # Temp files — opencode and child processes write here
            /tmp/                                                                  r,
            owner /tmp/                                                            rwk,
            owner /tmp/**                                                          rwklm,

            # System directories — read-only for enumeration and config
            /                                                                      r,
            /etc/                                                                  r,
            /etc/**                                                                r,
            /usr/                                                                  r,
            /var/                                                                  r,
            /run/                                                                  r,

            # Proc — basic process info (no environ, no other PIDs' memory)
            @{PROC}/                                                               r,
            @{PROC}/version                                                        r,
            @{PROC}/@{pid}/stat                                                    r,
            @{PROC}/@{pid}/statm                                                   r,
            @{PROC}/@{pid}/status                                                  r,
            @{PROC}/@{pid}/cmdline                                                 r,
            @{PROC}/@{pid}/cgroup                                                  r,
            @{PROC}/@{pid}/loginuid                                                r,
            @{PROC}/@{pid}/mountinfo                                               r,
            @{PROC}/sys/kernel/yama/ptrace_scope                                   r,
            @{PROC}/sys/vm/mmap_min_addr                                           r,
            @{PROC}/sys/vm/nr_hugepages                                            r,

            # Sys — hardware info (CPU, devices, memory settings, cgroup limits)
            @{sys}/                                                                r,
            @{sys}/devices/system/cpu/**                                           r,
            @{sys}/kernel/mm/transparent_hugepage/enabled                          r,
            # cgroup v2 — resource limits read by runtimes (Node, Bun, nix, etc.)
            # for CPU/memory monitoring and container awareness.
            @{sys}/fs/cgroup/**                                                    r,

            # D-Bus — desktop notifications, settings
            owner @{run}/user/@{uid}/bus                                           rw,

            # Silencer
            deny /etc/opt/                                                         w,

            include if exists <local/opencode>
          }
        '';
      };
    };
  };
}
