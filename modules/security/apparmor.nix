{ config, lib, pkgs, ... }:
{
  security.apparmor.killUnconfinedConfinables = true;
  security.apparmor.enable = true;
  security.apparmor.packages = [ pkgs.apparmor-d-nix-patch ];
}
