{ config, pkgs, ... }:
{
  imports = [ ./common.nix ];
  boot.kernelParams = [ "lockdown=integrity" ];
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1;
    "kernel.perf_event_paranoid" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 0;
  };
}