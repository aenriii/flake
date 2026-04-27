{ config, lib, pkgs, ... }:
{
  # system permissions / disable emergency mode
  security.sudo.execWheelOnly = true;
  systemd.coredump.enable = false;
  systemd.enableEmergencyMode = false;
  nix.settings.sandbox = true;
  
  # tmpfs
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "25%";
  
  # security.*
  security.pam.services.login.failDelay = {
    enable = true;
    delay = 4000000;
  };
  security.pam.loginLimits = [
    { domain = "@users"; item = "nproc";  type = "soft"; value = "1024"; }
    { domain = "@users"; item = "nproc";  type = "hard"; value = "8192"; }
  ];
  security.virtualisation.flushL1DataCache = "always";
  # security.lockKernelModules = true; note: think more about this? how nixos handles kernel modules during rebuilds...
  
  # memory allocator
  environment.memoryAllocator.provider = "scudo";
  environment.variables.SCUDO_OPTIONS = ""; # fails without this for some reason?
  
  # auditd
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"         # log all executed commands
    "-w /etc/passwd -p wa"                           # watch passwd changes
    "-w /etc/shadow -p wa"                           # watch shadow changes
    "-w /persist/secureboot -p wa"                   # watch secure boot keys
  ];
}