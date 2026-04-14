# Linux hardened kernel rules based on [ANSSI](https://cyber.gouv.fr/) recommendations.
# Intermediate level rules - should be applied after the minimal level settings.
# See: https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf

{ config, lib, ... }: {
  # Declare options
  options = {
    curios.anssi.intermediate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Intermediate hardening rules for a Linux system as recommended by ANSSI. Enable this after curios.anssi.minimal.enable.";
      };
      rule8 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "R8 - Linux kernel memory options. Note: Replaces legacy 'page_poison' with modern 'init_on_alloc/free' for Linux 6.12+ compatibility.";
      };
      rule9 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "R9 - Linux kernel sysctl options (updated for ANSSI v2.0 and Kernel 6.12+).";
      };
      rule11 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R11 - Linux kernel module LSM Yama.";
      };
      rule13 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "R13 - Deactivate IPv6. Enable this ONLY if you are NOT using IPv6.";
      };
      rule14 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "R14 - Filesystem sysctl options.";
      };
      rule39 = lib.mkOption {
        type = lib.types.bool;
        default = false;
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
      ] ++ lib.optionals config.curios.anssi.intermediate.rule11
        [ "lsm=capability,landlock,yama,bpf" ];

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
        }) // (lib.optionalAttrs config.curios.anssi.intermediate.rule11 {
          "kernel.yama.ptrace_scope" = 1; # Restricts ptrace to child processes
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

    security.sudo = lib.mkIf config.curios.anssi.intermediate.rule39 {
      extraConfig = ''
        Defaults noexec,use_pty,umask=0077
        Defaults ignore_dot,env_reset
      '';
    };
  };
}
