{ config, lib, pkgs, ... }:
{
  imports = [
    # ./systemd/global-harden.nix
  ];
  # system permissions / disable emergency mode
  security.sudo-rs.enable = true;
  security.sudo.enable = false;
  security.sudo-rs.execWheelOnly = true;
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
  security.pam.services.sudo.failDelay = {
    enable = true;
    delay = 4000000;
  };
  security.pam.services.greetd.failDelay = {
    enable = true;
    delay = 4000000;
  };
  security.pam.loginLimits = [
    { domain = "@users"; item = "nproc";  type = "soft"; value = "1024"; }
    { domain = "@users"; item = "nproc";  type = "hard"; value = "8192"; }
  ];
  
  security.virtualisation.flushL1DataCache = "always";
  security.lockKernelModules = true;
  security.allowSimultaneousMultithreading = !config.hostprofile.noCompromises; 
  
  # memory allocator
  environment.memoryAllocator.provider = "graphene-hardened";
  
  # auditd
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"         # log all executed commands
    "-w /etc/passwd -p wa"                           # watch passwd changes
    "-w /etc/shadow -p wa"                           # watch shadow changes
    "-w /persist/secureboot -p wa"                   # watch secure boot keys
    "-w /sbin/insmod -p w"                           # watch insmod changes
    "-w /sbin/modprobe -p w"                         # watch modprobe changes
    "-w /sbin/rmmod -p w"                            # watch rmmod changes
    "-w /etc/sudoers -p wa"                          # watch sudoers changes
    "-w /root/.ssh -p wa"                            # watch /root/.ssh changes
    "-a always,exit -F arch=b64 -S setuid -S setgid" # watch privilege changes
    "-a always,exit -F arch=b64 -S capset"           # watch capability changes
    "-a always,exit -F arch=b64 -S socket"           # watch socket changes
  ];
  
  # dbus -> dbus-broker
  services.dbus.implementation = "broker";
  
  # harden all systemd services with a sensible baseline.
  # individual services that need exceptions will override these.  
  # hide process IDs from non-root users
  fileSystems."/proc" = {
    device = "proc";
    fsType = "proc";
    options = [ "defaults" "hidepid=2" "gid=proc" ];
    neededForBoot = true;
  };
  
  # lower local network attack surface
  services.avahi.enable = false;
  services.printing.enable = false;
  hardware.bluetooth.powerOnBoot = false;
  
  # nix hardening
  nix.settings = {
    require-sigs = true;
    trusted-users = [ "aenri" ];
    allowed-users = [ "aenri" ];
  };
}