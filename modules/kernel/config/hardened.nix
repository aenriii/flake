{ lib, config, ... }:
let 
  use = (!config.hostprofile.noCompromises) && config.hostprofile.kernelConfig == "hardened";
in {
  # description = "hardened.nix - daily drivable hardening configuration";
  boot.kernelParams = lib.mkIf use [
    "lockdown=confidentiality"
    "spec_store_bypass_disable=on"
    "page_alloc.shuffle=1"
    "oops=panic"
    "slab_debug=ZP"
    "mds=full"
  ];
  boot.kernel.sysctl = lib.mkIf use {
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 3;
    "kernel.unprivileged_bpf_disabled" = 1;
  };  
}