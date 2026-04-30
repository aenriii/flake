{ lib, config, ... }:

let 
  use = (!config.hostprofile.noCompromises) && config.hostprofile.kernelConfig == "loose";
in {
  # description = "loose.nix - specifically configured to not break proton-battleye / steam";
  boot.kernelParams = lib.mkIf use [ "lockdown=integrity" ];
  boot.kernel.sysctl = lib.mkIf use {
    "kernel.unprivileged_userns_clone" = 1;
    "kernel.perf_event_paranoid" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 0;
  };
}