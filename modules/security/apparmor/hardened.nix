{ config, lib, pkgs, ... }:
{
  imports = [ ./common.nix ];
  security.apparmor.killUnconfinedConfinables = true;
}