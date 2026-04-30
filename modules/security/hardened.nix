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
  # lower local network attack surface
  services.avahi.enable = false;
  services.printing.enable = false;
  hardware.bluetooth.powerOnBoot = false;
}  