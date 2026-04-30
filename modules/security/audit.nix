{ config, lib, pkgs, ... }:
{
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
}