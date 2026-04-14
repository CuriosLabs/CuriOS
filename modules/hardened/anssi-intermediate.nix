# Linux hardened kernel rules based on [ANSSI](https://cyber.gouv.fr/) recommendations.
# Intermediate level rules - should be applied after the minimal level settings.
# See: https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.anssi.intermediate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "Intermediate hardening rules for a Linux system as recommended by ANSSI. Enable this after curios.anssi.minimal.enable.";
      };
      rule8 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "R8 - Linux kernel memory options. Note: Replaces legacy 'page_poison' with modern 'init_on_alloc/free' for Linux 6.12+ compatibility.";
      };
      rule9 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "R9 - Linux kernel sysctl options (updated for ANSSI v2.0 and Kernel 6.12+).";
      };
      rule11 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "R11 - Linux kernel module LSM Yama.";
      };
      rule12 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "R12 - BPF JIT and IPv4 network hardening.";
      };
      rule13 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "R13 - Deactivate IPv6. Enable this ONLY if you are NOT using IPv6.";
      };
      rule14 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "R14 - Filesystem sysctl options.";
      };
      rule39 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "R39 - /etc/sudoers extra configuration.";
      };
    };
  };

  config = lib.mkIf config.curios.anssi.intermediate.enable {
    boot = {
      kernelParams = lib.optionals config.curios.anssi.intermediate.rule8 [
        "init_on_alloc=1"
        "init_on_free=1"
        "slab_nomerge=yes"
        "slub_debug=FZP"
        "page_alloc.shuffle=1"
        "mitigations=auto"
        "spec_store_bypass_disable=seccomp"
        "mce=0"
        "rng_core.default_quality=500"
      ];

      kernel.sysctl =
        (lib.optionalAttrs config.curios.anssi.intermediate.rule9 {
          "kernel.dmesg_restrict" = 1;
          "kernel.kptr_restrict" = 2;
          "kernel.pid_max" = 1048576;
          "kernel.perf_cpu_time_max_percent" = 1;
          "kernel.perf_event_max_sample_rate" = 1;
          "kernel.perf_event_paranoid" = 2;
          "kernel.randomize_va_space" = 2;
          "kernel.sysrq" = 0;
          "kernel.unprivileged_bpf_disabled" = 1;
          "kernel.panic_on_oops" = 1;
        }) // (lib.optionalAttrs config.curios.anssi.intermediate.rule12 {
          "net.core.bpf_jit_harden" = 2; # Enables BPF JIT constant blinding
          "net.ipv4.conf.all.rp_filter" = 1; # Strict Reverse Path Filtering
          "net.ipv4.conf.default.rp_filter" = 1;
          "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Ignore ICMP broadcasts
          "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
          "net.ipv4.conf.all.accept_source_route" = 0; # Disables source routing
          "net.ipv4.conf.default.accept_source_route" = 0;
          "net.ipv4.tcp_syncookies" = 1; # Prevent SYN flood attack
        }) // (lib.optionalAttrs config.curios.anssi.intermediate.rule13 {
          "net.ipv6.conf.default.disable_ipv6" = 1;
          "net.ipv6.conf.all.disable_ipv6" = 1;
        }) // (lib.optionalAttrs config.curios.anssi.intermediate.rule14 {
          "fs.suid_dumpable" = 0;
          "fs.protected_fifos" = 2;
          "fs.protected_regular" = 2;
          "fs.protected_symlinks" = 1;
          "fs.protected_hardlinks" = 1;
        });
    };

    security = {
      lsm = lib.optionals config.curios.anssi.intermediate.rule11 [
        "capability"
        "landlock"
        "yama"
        "bpf"
      ];

      sudo = lib.mkIf config.curios.anssi.intermediate.rule39 {
        extraConfig = ''
          Defaults noexec,use_pty,umask=0077
          Defaults ignore_dot,env_reset
        '';
      };
    };
  };
}
