{ config, lib, pkgs, ... }:
{
  # disables sudo, sudo-rs is used instead.
  security.sudo-rs.enable = true;
  security.sudo.enable = false;
  security.sudo-rs.execWheelOnly = true;  
}