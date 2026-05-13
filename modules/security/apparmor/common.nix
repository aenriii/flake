{ config, lib, pkgs, ... }:
{
  imports = [ ./apparmor-d.nix ];
  security.apparmor.enable = true;
}
