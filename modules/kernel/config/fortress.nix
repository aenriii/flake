{ lib, config, ... }:

let 
  use = config.hostprofile.noCompromises || config.hostprofile.kernelConfig == "fortress";
in {
  # description = "fortress.nix - sacrifice everything for kernel security.";
  warnings = lib.mkIf use [ ''
    You are using the fortress kernel configuration. Expect a performance loss of up to 80%.
    This is not recommended for daily use. For a secure daily driver, use 'hardened'.
  '' ];
  boot.kernelParams = lib.mkIf use [
    "lockdown=confidentiality"
    "spec_store_bypass_disable=on"
    "page_alloc.shuffle=1"
    "oops=panic"
    "slab_debug=FZP"
    "mds=full,nosmt"
    "l1tf=full,nosmt"
    "nosmt"
  ];
  boot.kernel.sysctl = lib.mkIf use {
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 3;
    "kernel.unprivileged_bpf_disabled" = 1;
  };  
}