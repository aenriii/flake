{ config, pkgs, lib, ... }:
{
  imports = [ ./common.nix ];
  boot.kernelParams = [
    "lockdown=confidentiality"
    "spec_store_bypass_disable=on"
    "page_alloc.shuffle=1"
    "oops=panic"
  ];
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 3;
    "kernel.unprivileged_bpf_disabled" = 1;
  };  
}