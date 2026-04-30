{ config, lib, pkgs, ... }:
{
  imports = [
    ./systemd/general.nix
    ./sudo-rs.nix
    ./nix.nix
    ./pam.nix
    ./audit.nix
    ./fs.nix
  ];
  security.virtualisation.flushL1DataCache = "always";
  security.lockKernelModules = true;
  security.allowSimultaneousMultithreading = !config.hostprofile.noCompromises; 
  
  # memory allocator
  environment.memoryAllocator.provider = "graphene-hardened";

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
}  