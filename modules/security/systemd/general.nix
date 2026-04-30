{ config, lib, pkgs, ... }:
{
  systemd.coredump.enable = false;
  systemd.enableEmergencyMode = false;
}